require 'rails_helper'

RSpec.describe 'Reservation conflicts', type: :request do
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

  let(:day) { Date.today + 2.days }

  def create_reservation_unit_prefs(for_unit)
    [
      { name: 'contact_phone', value: '808 453-3245', pref_type: 'string', on_off: false },
      { name: 'unit_office', value: '123 Main St', pref_type: 'string', on_off: false },
      { name: 'reservation_time_begin', value: '08:00', pref_type: 'time', on_off: false },
      { name: 'reservation_time_end', value: '20:00', pref_type: 'time', on_off: false },
      { name: 'notification_email', value: 'admin@test.com', pref_type: 'string', on_off: false },
      { name: 'faculty_survey', value: nil, pref_type: 'boolean', on_off: false },
      { name: 'hours_before_reservation', value: '24', pref_type: 'integer', on_off: false },
      { name: 'no_car_reservations', value: nil, pref_type: 'boolean', on_off: false },
      { name: 'parking_location', value: 'Thayer 1A, Thayer 2', pref_type: 'string', on_off: true },
      { name: 'recurring_until', value: nil, pref_type: 'string', on_off: false },
      { name: 'send_reminders', value: nil, pref_type: 'string', on_off: false },
      { name: 'unit_email_message', value: nil, pref_type: 'string', on_off: false }
    ].each do |preference|
      FactoryBot.create(:unit_preference, preference.merge(unit: for_unit, description: preference[:name]))
    end
  end

  def day_time(hour)
    combine_day_and_time(day, format('%02d:00', hour))
  end

  def build_reservation(start_hour, end_hour, attrs = {})
    FactoryBot.create(
      :reservation,
      {
        program: program,
        site: site,
        car: car,
        number_of_people_on_trip: 1,
        start_time: day_time(start_hour) - 15.minute,
        end_time: day_time(end_hour) + 15.minute
      }.merge(attrs)
    )
  end

  def update_reservation(reservation, start_hour, end_hour, car_for_update = car)
    patch reservation_path(reservation), params: {
      reservation: {
        program_id: program.id,
        site_id: site.id,
        updated_by: reservation.updated_by
      },
      unit_id: unit.id,
      car_id: car_for_update.id,
      day_start: day.to_s,
      start_time: day_time(start_hour).to_s,
      end_time: day_time(end_hour).to_s,
      number_of_people_on_trip: 1
    }
  end

  context 'with admin role' do
    let!(:admin_user) { FactoryBot.create(:user) }

    before do
      create_reservation_unit_prefs(unit)
      stub_admin_access(admin_user, unit)
      mock_login(admin_user)
    end

    describe 'creating a reservation' do
      it 'does not create a reservation when the car is already reserved for that time' do
        build_reservation(10, 12)

        expect do
          post reservations_path, params: {
            reservation: { program_id: program.id, site_id: site.id },
            unit_id: unit.id,
            car_id: car.id,
            day_start: day.to_s,
            start_time: day_time(11).to_s,
            end_time: day_time(13).to_s,
            number_of_people_on_trip: 1,
            until_date: day.to_s
          }
        end.not_to change(Reservation, :count)

        expect(response).to have_http_status(422)
        expect(flash[:alert]).to eq('There is a conflict with another reservation. Please select different time.')
      end

      it 'creates the reservation when another car is reserved for that time' do
        build_reservation(10, 12)

        expect do
          post reservations_path, params: {
            reservation: { program_id: program.id, site_id: site.id },
            unit_id: unit.id,
            car_id: other_car.id,
            day_start: day.to_s,
            start_time: day_time(11).to_s,
            end_time: day_time(13).to_s,
            number_of_people_on_trip: 1,
            until_date: day.to_s
          }
        end.to change(Reservation, :count).by(1)

        expect(Reservation.last.status).to be_nil
      end
    end

    describe 'updating a reservation' do
      let!(:reservation) { build_reservation(8, 9, reserved_by: admin_user.id, updated_by: admin_user.id) }
      let!(:blocking) { build_reservation(14, 16) }

      it 'saves the reservation and flags both reservations when the update creates a conflict' do
        update_reservation(reservation, 14, 16)

        expect(response).to have_http_status(302)
        expect(flash[:alert]).to include('There is a conflict with another reservation')
        expect(reservation.reload.start_time).to eq(day_time(14) - 15.minute)
        expect(reservation.status).to eq(CONFLICT_STATUS)
        expect(blocking.reload.status).to eq(CONFLICT_STATUS)
      end

      it 'clears the status of both reservations when the conflict is resolved' do
        update_reservation(reservation, 14, 16)
        expect(blocking.reload.status).to eq(CONFLICT_STATUS)

        update_reservation(reservation, 8, 9)

        expect(reservation.reload.status).to be_nil
        expect(blocking.reload.status).to be_nil
      end

      it 'clears the conflict when the reservation is moved to another car' do
        update_reservation(reservation, 14, 16)

        update_reservation(reservation, 14, 16, other_car)

        expect(reservation.reload.car_id).to eq(other_car.id)
        expect(reservation.status).to be_nil
        expect(blocking.reload.status).to be_nil
      end

      it 'keeps the conflict status of a reservation that still conflicts with another one' do
        still_conflicting = build_reservation(15, 17)
        update_reservation(reservation, 14, 16)

        update_reservation(reservation, 8, 9)

        expect(reservation.reload.status).to be_nil
        expect(blocking.reload.status).to eq(CONFLICT_STATUS)
        expect(still_conflicting.reload.status).to eq(CONFLICT_STATUS)
      end
    end
  end

  context 'with student role' do
    let!(:student_user) { FactoryBot.create(:user) }
    let!(:student) { FactoryBot.create(:student, uniqname: student_user.uniqname, program: program) }
    let!(:reservation) do
      build_reservation(8, 9, driver: student, reserved_by: student_user.id, updated_by: student_user.id)
    end
    let!(:blocking) { build_reservation(14, 16) }

    before do
      create_reservation_unit_prefs(unit)
      stub_non_admin_access(student_user)
      mock_login(student_user)
    end

    it 'does not save the reservation when the update creates a conflict' do
      update_reservation(reservation, 14, 16)

      expect(response).to have_http_status(422)
      expect(flash[:alert]).to include('Please select a different time or ask admins to edit the reservation')
      expect(reservation.reload.start_time).to eq(day_time(8) - 15.minute)
      expect(reservation.status).to be_nil
      expect(blocking.reload.status).to be_nil
    end

    it 'saves the reservation when there is no conflict' do
      update_reservation(reservation, 10, 12)

      expect(response).to have_http_status(302)
      expect(reservation.reload.start_time).to eq(day_time(10) - 15.minute)
      expect(reservation.status).to be_nil
    end
  end
end
