require 'rails_helper'

RSpec.describe ReservationsController, type: :request do
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
  let!(:car) { FactoryBot.create(:car, unit: unit, status: :available) }

  def create_reservation_unit_prefs(for_unit)
    FactoryBot.create(
      :unit_preference,
      unit: for_unit,
      name: 'hours_before_reservation',
      description: 'Hours before reservation',
      pref_type: :integer,
      value: '24'
    )
    FactoryBot.create(
      :unit_preference,
      unit: for_unit,
      name: 'reservation_time_begin',
      description: 'Reservation start time',
      pref_type: :time,
      value: '08:00'
    )
    FactoryBot.create(
      :unit_preference,
      unit: for_unit,
      name: 'reservation_time_end',
      description: 'Reservation end time',
      pref_type: :time,
      value: '20:00'
    )
  end

  context 'with admin role' do
    let!(:admin_user) { FactoryBot.create(:user) }
    let!(:reservation) do
      FactoryBot.create(
        :reservation,
        program: program,
        site: site,
        car: car,
        reserved_by: admin_user.id,
        updated_by: admin_user.id,
        start_time: DateTime.current.change(hour: 10, min: 0),
        end_time: DateTime.current.change(hour: 12, min: 0)
      )
    end

    before do
      create_reservation_unit_prefs(unit)
      stub_admin_access(admin_user, unit)
      mock_login(admin_user)
    end

    it 'returns 200 for index' do
      reservation

      get reservations_path

      expect(response).to have_http_status(200)
      expect(response.body).to include('Reservations')
    end

    it 'returns 200 for day_reservations' do
      reservation

      get day_reservations_path(Date.today)

      expect(response).to have_http_status(200)
      expect(response.body).to include('Reservations for')
    end

    it 'returns 200 for canceled_reservations' do
      canceled = FactoryBot.create(
        :reservation,
        program: program,
        site: site,
        car: car,
        reserved_by: admin_user.id,
        updated_by: admin_user.id
      )
      canceled.update_columns(canceled: true, reason_for_cancellation: 'test reason')

      get canceled_reservations_path

      expect(response).to have_http_status(200)
      expect(response.body).to include('Canceled Reservations')
    end

    it 'redirects with alert when selected_reservations has no selected ids' do
      day = Date.today.to_s

      post selected_reservations_path, params: { day: day }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(day_reservations_path(day))
      expect(flash[:alert]).to eq('Please select at least one reservation.')
    end

    it 'returns 422 and renders email form when selected_reservations has ids' do
      reservation

      post selected_reservations_path, params: {
        day: Date.today.to_s,
        res_ids: {
          reservation.id.to_s => '0'
        }
      }

      expect(response).to have_http_status(422)
      expect(response.body).to include('Please fill out the form to send an email to the selected reservations')
    end

    it 'returns 200 for show' do
      get reservation_path(reservation)

      expect(response).to have_http_status(200)
    end

    it 'creates a reservation and redirects to add drivers and passengers' do
      day_start = Date.today + 1.day
      start_time = day_start.to_datetime.change(hour: 10, min: 0)
      end_time = day_start.to_datetime.change(hour: 11, min: 0)

      expect do
        post reservations_path, params: {
          reservation: {
            program_id: program.id,
            site_id: site.id
          },
          unit_id: unit.id,
          car_id: car.id,
          day_start: day_start.to_s,
          start_time: start_time.to_s,
          end_time: end_time.to_s,
          number_of_people_on_trip: 1,
          until_date: day_start.to_s
        }
      end.to change(Reservation, :count).by(1)

      created = Reservation.last
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(add_drivers_and_passengers_path(created))
      expect(created.program_id).to eq(program.id)
      expect(created.site_id).to eq(site.id)
      expect(created.car_id).to eq(car.id)
      expect(created.reserved_by).to eq(admin_user.id)
    end

    it 'returns 200 for edit' do
      get edit_reservation_path(reservation)

      expect(response).to have_http_status(200)
      expect(response.body).to include('Editing Reservation')
    end
  end

  context 'with manager role' do
    let!(:manager_user) { FactoryBot.create(:user) }
    let!(:manager) { FactoryBot.create(:manager, uniqname: manager_user.uniqname) }
    let!(:manager_program) { FactoryBot.create(:program, unit: unit, term: term, instructor: manager, title: 'Manager Reservation Program') }
    let!(:manager_reservation) do
      FactoryBot.create(
        :reservation,
        program: manager_program,
        site: site,
        car: car,
        driver_manager: manager,
        reserved_by: manager_user.id,
        updated_by: manager_user.id,
        start_time: DateTime.current.change(hour: 13, min: 0),
        end_time: DateTime.current.change(hour: 15, min: 0)
      )
    end

    before do
      create_reservation_unit_prefs(unit)
      stub_non_admin_access(manager_user)
      mock_login(manager_user)
    end

    it 'is authorized for show when manager is reservation driver' do
      get reservation_path(manager_reservation)

      expect(response).to have_http_status(200)
    end

    it 'creates a reservation and assigns current manager as driver_manager' do
      day_start = Date.today + 1.day
      start_time = day_start.to_datetime.change(hour: 10, min: 0)
      end_time = day_start.to_datetime.change(hour: 11, min: 0)

      expect do
        post reservations_path, params: {
          reservation: {
            program_id: manager_program.id,
            site_id: site.id
          },
          unit_id: unit.id,
          car_id: car.id,
          day_start: day_start.to_s,
          start_time: start_time.to_s,
          end_time: end_time.to_s,
          number_of_people_on_trip: 1,
          until_date: day_start.to_s
        }
      end.to change(Reservation, :count).by(1)

      created = Reservation.last
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(add_drivers_and_passengers_path(created))
      expect(created.driver_manager_id).to eq(manager.id)
      expect(created.reserved_by).to eq(manager_user.id)
    end

    it 'returns 200 for edit when manager is reservation driver' do
      get edit_reservation_path(manager_reservation)

      expect(response).to have_http_status(200)
      expect(response.body).to include('Editing Reservation')
    end

    it 'is not authorized for selected_reservations with ids' do
      post selected_reservations_path, params: {
        day: Date.today.to_s,
        res_ids: {
          manager_reservation.id.to_s => '0'
        }
      }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_manager_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is not authorized for canceled_reservations' do
      get canceled_reservations_path

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_manager_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end

  context 'with student role' do
    let!(:student_user) { FactoryBot.create(:user) }
    let!(:student) { FactoryBot.create(:student, uniqname: student_user.uniqname, program: program) }
    let!(:student_reservation) do
      FactoryBot.create(
        :reservation,
        program: program,
        site: site,
        car: car,
        driver: student,
        reserved_by: student_user.id,
        updated_by: student_user.id,
        start_time: DateTime.current.change(hour: 9, min: 0),
        end_time: DateTime.current.change(hour: 11, min: 0)
      )
    end

    before do
      create_reservation_unit_prefs(unit)
      stub_non_admin_access(student_user)
      mock_login(student_user)
    end

    it 'is authorized for show when student is reservation driver' do
      get reservation_path(student_reservation)

      expect(response).to have_http_status(200)
    end

    it 'creates a reservation and assigns current student as driver' do
      day_start = Date.today + 1.day
      start_time = day_start.to_datetime.change(hour: 9, min: 0)
      end_time = day_start.to_datetime.change(hour: 10, min: 0)

      expect do
        post reservations_path, params: {
          reservation: {
            program_id: program.id,
            site_id: site.id
          },
          unit_id: unit.id,
          car_id: car.id,
          day_start: day_start.to_s,
          start_time: start_time.to_s,
          end_time: end_time.to_s,
          number_of_people_on_trip: 1,
          until_date: day_start.to_s
        }
      end.to change(Reservation, :count).by(1)

      created = Reservation.last
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(add_drivers_and_passengers_path(created))
      expect(created.driver_id).to eq(student.id)
      expect(created.reserved_by).to eq(student_user.id)
    end

    it 'returns 200 for edit when student is reservation driver' do
      get edit_reservation_path(student_reservation)

      expect(response).to have_http_status(200)
      expect(response.body).to include('Editing Reservation')
    end

    it 'is not authorized for day_reservations' do
      get day_reservations_path(Date.today)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_student_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end

  context 'with none role' do
    let!(:user) { FactoryBot.create(:user) }
    let!(:reservation) { FactoryBot.create(:reservation, program: program, site: site, car: car) }

    before do
      create_reservation_unit_prefs(unit)
      stub_non_admin_access(user)
      mock_login(user)
    end

    it 'is not authorized for show' do
      get reservation_path(reservation)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is not authorized for index' do
      get reservations_path

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end
end
