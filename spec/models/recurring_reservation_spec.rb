require 'rails_helper'

RSpec.describe RecurringReservation, type: :model do
  include ApplicationHelper

  let!(:unit) { FactoryBot.create(:unit) }
  let!(:term) do
    FactoryBot.create(
      :term,
      classes_begin_date: Date.today - 7.days,
      classes_end_date: Date.today + 30.days
    )
  end
  let!(:instructor) { FactoryBot.create(:manager) }
  let!(:program) { FactoryBot.create(:program, unit: unit, term: term, instructor: instructor) }
  let!(:site) { FactoryBot.create(:site, unit: unit) }
  let!(:car) { FactoryBot.create(:car, unit: unit, status: :available, number_of_seats: 7) }
  let!(:other_car) { FactoryBot.create(:car, unit: unit, status: :available, number_of_seats: 7) }
  let!(:user) { FactoryBot.create(:user) }

  let(:day_one) { Date.today + 2.days }
  let(:day_two) { day_one + 1.day }
  let(:day_three) { day_one + 2.days }

  def day_time(day, hour)
    combine_day_and_time(day, format('%02d:00', hour))
  end

  def build_reservation(day, start_hour, end_hour, attrs = {})
    FactoryBot.create(
      :reservation,
      {
        program: program,
        site: site,
        car: car,
        reserved_by: user.id,
        updated_by: user.id,
        number_of_people_on_trip: 1,
        start_time: day_time(day, start_hour) - 15.minute,
        end_time: day_time(day, end_hour) + 15.minute
      }.merge(attrs)
    )
  end

  describe '#create_all' do
    let(:first_reservation) do
      build_reservation(
        day_one, 10, 12,
        recurring: { 'validations' => {}, 'rule_type' => 'IceCube::DailyRule', 'interval' => 1, 'count' => 3 },
        until_date: day_three
      )
    end

    it 'builds a valid recurring rule for the spec setup' do
      expect(first_reservation.recurring).to be_present
      expect(RecurringReservation.new(first_reservation).schedule.all_occurrences.count).to eq(3)
    end

    it 'creates the following reservations without a status when there are no conflicts' do
      message = RecurringReservation.new(first_reservation).create_all

      expect(message).to eq('')
      expect(Reservation.where(car: car).count).to eq(3)
      expect(Reservation.where(car: car).pluck(:status).uniq).to eq([nil])
    end

    it 'marks the new reservation and the existing reservation it conflicts with' do
      blocking = build_reservation(day_two, 11, 13)
      expect(blocking.status).to be_nil

      message = RecurringReservation.new(first_reservation).create_all

      expect(message).to include('There are conflicts with other reservations on')
      expect(message).to include(day_two.strftime('%B'))

      conflicting_new = Reservation.where(car: car, prev: first_reservation.id).first
      expect(conflicting_new.start_time.to_date).to eq(day_two)
      expect(conflicting_new.status).to eq(CONFLICT_STATUS)
      expect(blocking.reload.status).to eq(CONFLICT_STATUS)
    end

    it 'does not flag reservations on days without a conflict' do
      build_reservation(day_two, 11, 13)

      RecurringReservation.new(first_reservation).create_all

      day_three_reservation = Reservation.where(car: car).find { |r| r.start_time.to_date == day_three }
      expect(day_three_reservation.status).to be_nil
    end

    it 'does not flag a reservation on another car' do
      blocking = build_reservation(day_two, 11, 13, car: other_car)

      message = RecurringReservation.new(first_reservation).create_all

      expect(message).to eq('')
      expect(blocking.reload.status).to be_nil
    end

    it 'does not flag existing reservations when the conflicting occurrence fails to save' do
      blocking = build_reservation(day_two, 11, 13)
      first_reservation
      allow_any_instance_of(Reservation).to receive(:save!).and_wrap_original do |original, *args|
        record = original.receiver
        raise ActiveRecord::RecordInvalid.new(record) if record.new_record? && record.start_time.to_date == day_two
        original.call(*args)
      end

      message = RecurringReservation.new(first_reservation).create_all

      expect(message).to include('Reservations were not created on')
      expect(message).not_to include('There are conflicts')
      expect(blocking.reload.status).to be_nil
      day_three_reservation = Reservation.where(car: car).find { |r| r.start_time.to_date == day_three }
      expect(day_three_reservation.prev).to eq(first_reservation.id)
      expect(first_reservation.reload.next).to eq(day_three_reservation.id)
    end
  end

  describe '#first_reservation and #last_reservation' do
    let!(:reservation_one) { build_reservation(day_one, 10, 12) }
    let!(:reservation_two) { build_reservation(day_two, 10, 12) }
    let!(:reservation_three) { build_reservation(day_three, 10, 12) }
    let(:missing_id) { Reservation.unscoped.maximum(:id) + 1000 }

    it 'follows reciprocal links to both ends of the chain' do
      reservation_one.update(next: reservation_two.id)
      reservation_two.update(prev: reservation_one.id, next: reservation_three.id)
      reservation_three.update(prev: reservation_two.id)

      expect(RecurringReservation.new(reservation_two.reload).first_reservation).to eq(reservation_one)
      expect(RecurringReservation.new(reservation_two.reload).last_reservation).to eq(reservation_three)
    end

    it 'stops at the current reservation when the linked record is missing' do
      reservation_two.update(prev: missing_id, next: missing_id)

      expect(RecurringReservation.new(reservation_two.reload).first_reservation).to eq(reservation_two)
      expect(RecurringReservation.new(reservation_two.reload).last_reservation).to eq(reservation_two)
    end

    it 'stops at the current reservation when the link is not reciprocal' do
      reservation_one.update(next: reservation_three.id)
      reservation_three.update(prev: reservation_one.id)
      reservation_two.update(prev: reservation_one.id, next: reservation_three.id)

      expect(RecurringReservation.new(reservation_two.reload).first_reservation).to eq(reservation_two)
      expect(RecurringReservation.new(reservation_two.reload).last_reservation).to eq(reservation_two)
    end

    it 'stops before revisiting a reservation when reciprocal links form a cycle' do
      reservation_one.update(prev: reservation_two.id, next: reservation_two.id)
      reservation_two.update(prev: reservation_one.id, next: reservation_one.id)

      expect(RecurringReservation.new(reservation_one.reload).first_reservation).to eq(reservation_two)
      expect(RecurringReservation.new(reservation_one.reload).last_reservation).to eq(reservation_two)
    end

    it 'does not change the wrapped reservation' do
      reservation_one.update(next: reservation_two.id)
      reservation_two.update(prev: reservation_one.id, next: reservation_three.id)
      reservation_three.update(prev: reservation_two.id)
      recurring = RecurringReservation.new(reservation_two.reload)

      recurring.first_reservation
      recurring.last_reservation

      expect(recurring.reservation).to eq(reservation_two)
      expect(recurring.get_following).to eq([reservation_two.id, reservation_three.id])
    end

    it 'returns consistent results and terminates on a reciprocal cycle' do
      reservation_one.update(prev: reservation_two.id, next: reservation_two.id)
      reservation_two.update(prev: reservation_one.id, next: reservation_one.id)
      recurring = RecurringReservation.new(reservation_one.reload)

      expect(recurring.first_reservation).to eq(reservation_two)
      expect(recurring.first_reservation).to eq(reservation_two)
      expect(recurring.get_all_reservations).to eq([reservation_two.id, reservation_one.id])
      expect(recurring.get_following).to eq([reservation_one.id, reservation_two.id])
    end
  end

  describe '#update_this_and_following' do
    let!(:reservation_one) { build_reservation(day_one, 10, 12) }
    let!(:reservation_two) { build_reservation(day_two, 10, 12, prev: reservation_one.id) }

    before do
      reservation_one.update(next: reservation_two.id)
    end

    def update_params(car_id = car.id)
      {
        'site_id' => site.id,
        'updated_by' => user.id,
        'car_id' => car_id,
        'number_of_people_on_trip' => 1
      }
    end

    def update_following(start_hour, end_hour, admin: true, car_id: car.id)
      RecurringReservation.new(reservation_one.reload).update_this_and_following(
        update_params(car_id),
        day_time(day_one, start_hour) - 15.minute,
        day_time(day_one, end_hour) + 15.minute,
        admin
      )
    end

    it 'flags the updated reservations and the reservations they conflict with' do
      blocking = build_reservation(day_two, 14, 16)

      update_following(14, 16)

      expect(reservation_two.reload.status).to eq(CONFLICT_STATUS)
      expect(blocking.reload.status).to eq(CONFLICT_STATUS)
      expect(reservation_one.reload.status).to be_nil
    end

    it 'clears the status of the recurring reservation and of the reservation it used to conflict with' do
      blocking = build_reservation(day_two, 14, 16)
      update_following(14, 16)
      expect(blocking.reload.status).to eq(CONFLICT_STATUS)

      update_following(8, 9)

      expect(reservation_two.reload.status).to be_nil
      expect(blocking.reload.status).to be_nil
    end

    it 'keeps the conflict status of a reservation that still conflicts with something else' do
      blocking = build_reservation(day_two, 14, 16)
      still_conflicting = build_reservation(day_two, 15, 17)
      update_following(14, 16)

      update_following(8, 9)

      expect(reservation_two.reload.status).to be_nil
      expect(blocking.reload.status).to eq(CONFLICT_STATUS)
      expect(still_conflicting.reload.status).to eq(CONFLICT_STATUS)
    end

    it 'does not update reservations for non admins when there is a conflict' do
      blocking = build_reservation(day_two, 14, 16)

      message = update_following(14, 16, admin: false)

      expect(message).to include('There are conflicts with other reservations on')
      expect(reservation_two.reload.start_time.hour).to eq(9)
      expect(reservation_two.reload.status).to be_nil
      expect(blocking.reload.status).to be_nil
    end

    it 'rolls back an occurrence and reports it when a conflicting reservation cannot be flagged' do
      blocking = build_reservation(day_two, 14, 16)
      blocking_id = blocking.id
      allow_any_instance_of(Reservation).to receive(:update!).and_wrap_original do |original, *args|
        raise ActiveRecord::RecordInvalid.new(original.receiver) if original.receiver.id == blocking_id
        original.call(*args)
      end

      message = update_following(14, 16)

      expect(message).to include("Reservation #{reservation_two.id} was not updated")
      expect(reservation_two.reload.start_time).to eq(day_time(day_two, 10) - 15.minute)
      expect(reservation_two.status).to be_nil
      expect(blocking.reload.status).to be_nil
      expect(reservation_one.reload.start_time).to eq(day_time(day_one, 14) - 15.minute)
    end

    it 'lets non admins remove the car even when the old car is taken at the new time' do
      build_reservation(day_two, 14, 16)

      message = update_following(14, 16, admin: false, car_id: '')

      expect(message).to eq('')
      expect(reservation_two.reload.car_id).to be_nil
      expect(reservation_two.status).to be_nil
    end

    it 'clears conflicts on the old car when admins remove the car' do
      blocking = build_reservation(day_two, 14, 16)
      update_following(14, 16)
      expect(blocking.reload.status).to eq(CONFLICT_STATUS)

      update_following(14, 16, car_id: '')

      expect(reservation_two.reload.car_id).to be_nil
      expect(reservation_two.status).to be_nil
      expect(blocking.reload.status).to be_nil
    end
  end

  describe 'overnight recurring reservations' do
    let(:day_four) { day_one + 3.days }

    # starts on day at start_hour and ends on the following day at end_hour
    def build_overnight_reservation(day, start_hour, end_hour, attrs = {})
      build_reservation(day, start_hour, end_hour, {
        start_time: day_time(day, start_hour) - 15.minute,
        end_time: day_time(day + 1.day, end_hour) + 15.minute
      }.merge(attrs))
    end

    describe '#create_all' do
      let(:first_reservation) do
        build_overnight_reservation(
          day_one, 18, 8,
          recurring: { 'validations' => {}, 'rule_type' => 'IceCube::DailyRule', 'interval' => 2, 'count' => 2 },
          until_date: day_three
        )
      end

      it 'creates the following overnight reservations ending on the next day' do
        message = RecurringReservation.new(first_reservation).create_all

        following = Reservation.find_by(prev: first_reservation.id)
        expect(message).to eq('')
        expect(following.start_time).to eq(day_time(day_three, 18) - 15.minute)
        expect(following.end_time).to eq(day_time(day_four, 8) + 15.minute)
        expect(following.status).to be_nil
      end

      it 'flags the following overnight reservation and the next morning reservation it conflicts with' do
        next_morning = build_reservation(day_four, 7, 9)

        message = RecurringReservation.new(first_reservation).create_all

        following = Reservation.find_by(prev: first_reservation.id)
        expect(message).to include('There are conflicts with other reservations on')
        expect(following.status).to eq(CONFLICT_STATUS)
        expect(next_morning.reload.status).to eq(CONFLICT_STATUS)
        expect(first_reservation.reload.status).to be_nil
      end
    end

    describe '#update_this_and_following' do
      let!(:reservation_one) { build_overnight_reservation(day_one, 18, 8) }
      let!(:reservation_two) { build_overnight_reservation(day_three, 18, 8, prev: reservation_one.id) }

      before do
        reservation_one.update(next: reservation_two.id)
      end

      def update_following(start_hour, end_hour, admin: true)
        RecurringReservation.new(reservation_one.reload).update_this_and_following(
          { 'site_id' => site.id, 'updated_by' => user.id, 'car_id' => car.id, 'number_of_people_on_trip' => 1 },
          day_time(day_one, start_hour) - 15.minute,
          day_time(day_two, end_hour) + 15.minute,
          admin
        )
      end

      it 'keeps the overnight end day and flags the reservation it now conflicts with the next morning' do
        next_morning = build_reservation(day_four, 9, 11)

        update_following(18, 10)

        expect(reservation_two.reload.end_time).to eq(day_time(day_four, 10) + 15.minute)
        expect(reservation_two.status).to eq(CONFLICT_STATUS)
        expect(next_morning.reload.status).to eq(CONFLICT_STATUS)
        expect(reservation_one.reload.status).to be_nil
      end

      it 'clears the conflict of the next morning reservation when the overnight reservations end earlier' do
        next_morning = build_reservation(day_four, 9, 11)
        update_following(18, 10)
        expect(next_morning.reload.status).to eq(CONFLICT_STATUS)

        update_following(18, 8)

        expect(reservation_two.reload.status).to be_nil
        expect(next_morning.reload.status).to be_nil
      end

      it 'does not update the overnight reservations for non admins when there is a conflict' do
        build_reservation(day_four, 9, 11)

        message = update_following(18, 10, admin: false)

        expect(message).to include('There are conflicts with other reservations on')
        expect(reservation_two.reload.end_time).to eq(day_time(day_four, 8) + 15.minute)
      end
    end
  end
end
