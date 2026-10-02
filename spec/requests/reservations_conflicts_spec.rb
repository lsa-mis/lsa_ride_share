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

  # overnight reservations start on day and end on next_day
  let(:next_day) { day + 1.day }

  def time_on(on_day, hour)
    combine_day_and_time(on_day, format('%02d:00', hour))
  end

  def build_overnight_reservation(start_hour, end_hour, attrs = {})
    build_reservation(start_hour, end_hour, {
      start_time: time_on(day, start_hour) - 15.minute,
      end_time: time_on(next_day, end_hour) + 15.minute
    }.merge(attrs))
  end

  def build_next_day_reservation(start_hour, end_hour, attrs = {})
    build_reservation(start_hour, end_hour, {
      start_time: time_on(next_day, start_hour) - 15.minute,
      end_time: time_on(next_day, end_hour) + 15.minute
    }.merge(attrs))
  end

  def update_overnight_reservation(reservation, start_hour, end_hour, car_for_update = car)
    patch reservation_path(reservation), params: {
      reservation: {
        program_id: program.id,
        site_id: site.id,
        updated_by: reservation.updated_by
      },
      unit_id: unit.id,
      car_id: car_for_update.id,
      day_start: day.to_s,
      day_end: next_day.to_s,
      start_time: time_on(day, start_hour).to_s,
      end_time: time_on(next_day, end_hour).to_s,
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

      it 'approves the reservation without changing other attributes through the approve switch' do
        reservation.update_columns(driver_id: FactoryBot.create(:student, program: program).id)
        patch reservation_path(reservation), params: { reservation: {
          approved: '1', car_id: other_car.id,
          start_time: (day_time(14) - 15.minute).to_s, end_time: (day_time(16) + 15.minute).to_s
        } }

        expect(response).to have_http_status(302)
        expect(reservation.reload.approved).to be(true)
        expect(reservation.car_id).to eq(car.id)
        expect(reservation.start_time).to eq(day_time(8) - 15.minute)
      end

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

      it 'rolls back the update when a conflicting reservation cannot be flagged' do
        blocking_id = blocking.id
        allow_any_instance_of(Reservation).to receive(:update!).and_wrap_original do |original, *args|
          raise ActiveRecord::RecordInvalid.new(original.receiver) if original.receiver.id == blocking_id
          original.call(*args)
        end

        update_reservation(reservation, 14, 16)

        expect(response).to have_http_status(422)
        expect(reservation.reload.start_time).to eq(day_time(8) - 15.minute)
        expect(reservation.status).to be_nil
        expect(blocking.reload.status).to be_nil
      end
    end

    describe 'canceling a conflicting reservation' do
      let!(:reservation) { build_reservation(14, 16, status: CONFLICT_STATUS, reserved_by: admin_user.id, updated_by: admin_user.id) }
      let!(:blocking) { build_reservation(14, 16, status: CONFLICT_STATUS) }

      it 'clears the conflict status of the remaining reservation' do
        get cancel_reservation_path(reservation), params: { reason_for_cancellation: 'No longer needed' }

        expect(response).to have_http_status(302)
        expect(Reservation.canceled.find(reservation.id).canceled).to be true
        expect(blocking.reload.status).to be_nil
      end

      it 'clears the conflict status even when the remaining reservation fails unrelated validations' do
        blocking_id = blocking.id
        allow_any_instance_of(Reservation).to receive(:valid?).and_wrap_original do |original, *args|
          original.receiver.id == blocking_id ? false : original.call(*args)
        end

        get cancel_reservation_path(reservation), params: { reason_for_cancellation: 'No longer needed' }

        expect(blocking.reload.status).to be_nil
      end

      it 'keeps the conflict status of a reservation that still conflicts with another one' do
        still_conflicting = build_reservation(15, 17, status: CONFLICT_STATUS)

        get cancel_reservation_path(reservation), params: { reason_for_cancellation: 'No longer needed' }

        expect(blocking.reload.status).to eq(CONFLICT_STATUS)
        expect(still_conflicting.reload.status).to eq(CONFLICT_STATUS)
      end

      it 'clears the conflict status when canceled through the recurring cancel action' do
        get cancel_recurring_reservation_path(reservation), params: { cancel_type: 'one', reason_for_cancellation: 'No longer needed' }

        expect(response).to have_http_status(302)
        expect(Reservation.canceled.find(reservation.id).canceled).to be true
        expect(blocking.reload.status).to be_nil
      end
    end

    describe 'overnight reservations' do
      def get_available_cars_long(last_day, start_hour, end_hour)
        get "/reservations/get_available_cars_long/#{unit.id}/#{day}/#{last_day}/1/" \
          "#{CGI.escape(time_on(day, start_hour).to_s)}/#{CGI.escape(time_on(last_day, end_hour).to_s)}/#{day}",
          headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      end

      [1, 2].each do |nights|
        it "does not offer a car that is reserved on the last morning of a #{nights} night reservation" do
          last_day = day + nights.days
          build_reservation(9, 11, start_time: time_on(last_day, 9) - 15.minute, end_time: time_on(last_day, 11) + 15.minute)

          get_available_cars_long(last_day, 16, 10)

          expect(response).to have_http_status(200)
          expect(response.body).not_to include(car.car_number)
          expect(response.body).to include(other_car.car_number)
        end
      end

      it 'does not offer a car that is reserved on a day between the first and the last day' do
        middle_day = day + 2.days
        build_reservation(10, 12, start_time: time_on(middle_day, 10) - 15.minute, end_time: time_on(middle_day, 12) + 15.minute)

        get_available_cars_long(day + 4.days, 16, 10)

        expect(response.body).not_to include(car.car_number)
        expect(response.body).to include(other_car.car_number)
      end

      it 'does not offer a car that is reserved for longer than the whole overnight reservation' do
        build_reservation(8, 20, start_time: time_on(day, 8) - 15.minute, end_time: time_on(day + 3.days, 20) + 15.minute)

        get_available_cars_long(day + 2.days, 16, 10)

        expect(response.body).not_to include(car.car_number)
        expect(response.body).to include(other_car.car_number)
      end

      it 'offers a car that is reserved only after the overnight reservation ends' do
        build_next_day_reservation(14, 16)

        get_available_cars_long(next_day, 16, 10)

        expect(response.body).to include(car.car_number)
      end

      it 'does not create an overnight reservation when the car is reserved the next morning' do
        build_next_day_reservation(9, 11)

        expect do
          post reservations_path, params: {
            reservation: { program_id: program.id, site_id: site.id },
            unit_id: unit.id,
            car_id: car.id,
            day_start: day.to_s,
            day_end: next_day.to_s,
            start_time: time_on(day, 16).to_s,
            end_time: time_on(next_day, 10).to_s,
            number_of_people_on_trip: 1,
            until_date: day.to_s
          }
        end.not_to change(Reservation, :count)

        expect(response).to have_http_status(422)
        expect(flash[:alert]).to eq('There is a conflict with another reservation. Please select different time.')
      end

      it 'creates an overnight reservation that ends before the next morning reservation' do
        build_next_day_reservation(14, 16)

        expect do
          post reservations_path, params: {
            reservation: { program_id: program.id, site_id: site.id },
            unit_id: unit.id,
            car_id: car.id,
            day_start: day.to_s,
            day_end: next_day.to_s,
            start_time: time_on(day, 16).to_s,
            end_time: time_on(next_day, 10).to_s,
            number_of_people_on_trip: 1,
            until_date: day.to_s
          }
        end.to change(Reservation, :count).by(1)

        expect(Reservation.last.status).to be_nil
      end

      it 'flags both reservations when an overnight update overlaps the next morning reservation' do
        reservation = build_overnight_reservation(16, 8, reserved_by: admin_user.id, updated_by: admin_user.id)
        blocking = build_next_day_reservation(11, 13)

        update_overnight_reservation(reservation, 16, 12)

        expect(response).to have_http_status(302)
        expect(reservation.reload.end_time).to eq(time_on(next_day, 12) + 15.minute)
        expect(reservation.status).to eq(CONFLICT_STATUS)
        expect(blocking.reload.status).to eq(CONFLICT_STATUS)
      end

      it 'flags both reservations when a one day reservation is extended overnight into another reservation' do
        reservation = build_reservation(14, 16, reserved_by: admin_user.id, updated_by: admin_user.id)
        blocking = build_next_day_reservation(9, 11)

        update_overnight_reservation(reservation, 14, 10)

        expect(response).to have_http_status(302)
        expect(reservation.reload.end_time).to eq(time_on(next_day, 10) + 15.minute)
        expect(reservation.status).to eq(CONFLICT_STATUS)
        expect(blocking.reload.status).to eq(CONFLICT_STATUS)
      end

      it 'clears the status of both reservations when the overnight conflict is resolved' do
        reservation = build_overnight_reservation(16, 12, status: CONFLICT_STATUS, reserved_by: admin_user.id, updated_by: admin_user.id)
        blocking = build_next_day_reservation(11, 13, status: CONFLICT_STATUS)

        update_overnight_reservation(reservation, 16, 9)

        expect(response).to have_http_status(302)
        expect(reservation.reload.status).to be_nil
        expect(blocking.reload.status).to be_nil
      end

      it 'clears the conflict of the next morning reservation when the overnight reservation is canceled' do
        reservation = build_overnight_reservation(16, 12, status: CONFLICT_STATUS, reserved_by: admin_user.id, updated_by: admin_user.id)
        blocking = build_next_day_reservation(11, 13, status: CONFLICT_STATUS)

        get cancel_reservation_path(reservation), params: { reason_for_cancellation: 'No longer needed' }

        expect(response).to have_http_status(302)
        expect(blocking.reload.status).to be_nil
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

    it 'does not save an overnight update that overlaps the next morning reservation' do
      next_morning = build_next_day_reservation(9, 11)

      update_overnight_reservation(reservation, 16, 10)

      expect(response).to have_http_status(422)
      expect(response.body).to include('End Time Overnight')
      expect(flash[:alert]).to include('Please select a different time or ask admins to edit the reservation')
      expect(reservation.reload.end_time).to eq(day_time(9) + 15.minute)
      expect(reservation.status).to be_nil
      expect(next_morning.reload.status).to be_nil
    end

    it 'saves the reservation when there is no conflict' do
      update_reservation(reservation, 10, 12)

      expect(response).to have_http_status(302)
      expect(reservation.reload.start_time).to eq(day_time(10) - 15.minute)
      expect(reservation.status).to be_nil
    end

    it 'ignores car and times nested in reservation params' do
      patch reservation_path(reservation), params: {
        reservation: {
          program_id: program.id,
          site_id: site.id,
          updated_by: student_user.id,
          car_id: car.id,
          start_time: (day_time(14) - 15.minute).to_s,
          end_time: (day_time(16) + 15.minute).to_s
        },
        unit_id: unit.id,
        car_id: other_car.id,
        day_start: day.to_s,
        start_time: day_time(10).to_s,
        end_time: day_time(12).to_s,
        number_of_people_on_trip: 1
      }

      expect(response).to have_http_status(302)
      expect(reservation.reload.car_id).to eq(other_car.id)
      expect(reservation.start_time).to eq(day_time(10) - 15.minute)
      expect(reservation.end_time).to eq(day_time(12) + 15.minute)
      expect(blocking.reload.status).to be_nil
    end

    it 'does not cancel the reservation through the update action' do
      update_reservation_params = {
        reservation: { program_id: program.id, site_id: site.id, updated_by: student_user.id, canceled: true },
        unit_id: unit.id,
        car_id: car.id,
        day_start: day.to_s,
        start_time: day_time(8).to_s,
        end_time: day_time(9).to_s,
        number_of_people_on_trip: 1
      }
      patch reservation_path(reservation), params: update_reservation_params

      expect(Reservation.find_by(id: reservation.id)).to be_present
    end

    it 'does not cancel the reservation through the approve branch of the update action' do
      patch reservation_path(reservation), params: { reservation: { approved: 'false', canceled: true } }

      expect(Reservation.find_by(id: reservation.id)).to be_present
    end

    it 'does not cancel the reservation through add_non_uofm_passengers' do
      patch add_non_uofm_passengers_path(reservation), params: { reservation: { canceled: true } }, as: :turbo_stream

      expect(Reservation.find_by(id: reservation.id)).to be_present
    end

    it 'does not let the driver approve the reservation' do
      patch reservation_path(reservation), params: { reservation: { approved: '1' } }

      expect(response).to have_http_status(302)
      expect(flash[:alert]).to eq('You are not authorized to perform this action.')
      expect(reservation.reload.approved).to be_falsey
    end

    it 'does not let the driver unapprove the reservation with an empty approved value' do
      reservation.update_columns(approved: true)
      update_reservation_params = {
        reservation: { program_id: program.id, site_id: site.id, updated_by: student_user.id, approved: '' },
        unit_id: unit.id,
        car_id: car.id,
        day_start: day.to_s,
        start_time: day_time(10).to_s,
        end_time: day_time(12).to_s,
        number_of_people_on_trip: 1
      }
      patch reservation_path(reservation), params: update_reservation_params

      expect(flash[:alert]).to eq('You are not authorized to perform this action.')
      expect(reservation.reload.approved).to be(true)
      expect(reservation.start_time).to eq(day_time(8) - 15.minute)
    end

    it 'does not let the student create an approved reservation' do
      post reservations_path, params: {
        reservation: { program_id: program.id, site_id: site.id, approved: '1' },
        unit_id: unit.id,
        car_id: other_car.id,
        day_start: day.to_s,
        start_time: day_time(11).to_s,
        end_time: day_time(13).to_s,
        number_of_people_on_trip: 1,
        until_date: day.to_s
      }

      expect(Reservation.last).not_to eq(reservation)
      expect(Reservation.last.approved).to be_falsey
    end

    it 'does not move the reservation into a taken slot through the approve branch of the update action' do
      patch reservation_path(reservation), params: { reservation: {
        approved: 'false', car_id: car.id, status: nil,
        start_time: (day_time(14) - 15.minute).to_s, end_time: (day_time(16) + 15.minute).to_s
      } }

      expect(reservation.reload.start_time).to eq(day_time(8) - 15.minute)
      expect(reservation.end_time).to eq(day_time(9) + 15.minute)
      expect(blocking.reload.status).to be_nil
    end

    it 'does not move the reservation into a taken slot through add_non_uofm_passengers' do
      patch add_non_uofm_passengers_path(reservation), params: { reservation: {
        car_id: other_car.id,
        start_time: (day_time(14) - 15.minute).to_s, end_time: (day_time(16) + 15.minute).to_s
      } }, as: :turbo_stream

      expect(reservation.reload.car_id).to eq(car.id)
      expect(reservation.start_time).to eq(day_time(8) - 15.minute)
      expect(reservation.end_time).to eq(day_time(9) + 15.minute)
      expect(blocking.reload.status).to be_nil
    end

    it 'saves non UofM passengers through add_non_uofm_passengers' do
      patch add_non_uofm_passengers_path(reservation), params: { reservation: {
        number_of_non_uofm_passengers: 1, non_uofm_passengers: 'Jane Doe'
      } }, as: :turbo_stream

      expect(reservation.reload.number_of_non_uofm_passengers).to eq(1)
      expect(reservation.non_uofm_passengers).to eq('Jane Doe')
    end

    it 'cancels the reservation through the cancel_reservation action' do
      get cancel_reservation_path(reservation), params: { reason_for_cancellation: 'not needed' }

      expect(Reservation.find_by(id: reservation.id)).to be_nil
      expect(Reservation.canceled.find(reservation.id).reason_for_cancellation).to eq('not needed')
    end
  end
end
