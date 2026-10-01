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
end
