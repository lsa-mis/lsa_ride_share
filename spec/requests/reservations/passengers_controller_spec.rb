require 'rails_helper'

RSpec.describe Reservations::PassengersController, type: :request do
  let!(:unit) { FactoryBot.create(:unit) }
  let!(:term) { FactoryBot.create(:term) }
  let!(:instructor) { FactoryBot.create(:manager) }
  let!(:program) { FactoryBot.create(:program, unit: unit, term: term, instructor: instructor) }
  let!(:site) { FactoryBot.create(:site, unit: unit) }
  let!(:car) { FactoryBot.create(:car, unit: unit, status: :available) }

  let!(:driver_student) do
    FactoryBot.create(
      :student,
      program: program,
      mvr_status: 'Approved until 2030-12-31',
      phone_number: '734-000-0001'
    )
  end
  let!(:passenger_student) do
    FactoryBot.create(
      :student,
      program: program,
      mvr_status: 'Approved until 2030-12-31',
      phone_number: '734-000-0002'
    )
  end
  let!(:other_student) do
    FactoryBot.create(
      :student,
      program: program,
      mvr_status: 'Approved until 2030-12-31',
      phone_number: '734-000-0003'
    )
  end

  let!(:reservation_owner) { FactoryBot.create(:user) }
  let!(:reservation) do
    FactoryBot.create(
      :reservation,
      program: program,
      site: site,
      car: car,
      driver: driver_student,
      reserved_by: reservation_owner.id,
      updated_by: reservation_owner.id,
      number_of_people_on_trip: 4
    )
  end

  context 'with admin role' do
    let!(:admin_user) { FactoryBot.create(:user) }

    before do
      stub_admin_access(admin_user, unit)
      mock_login(admin_user)
    end

    it 'returns 200 for add_drivers_and_passengers' do
      get add_drivers_and_passengers_path(reservation)

      expect(response).to have_http_status(200)
      expect(response.body).to include('Add Drivers and Passengers')
    end

    it 'adds a student passenger and redirects back to add drivers and passengers' do
      expect do
        get add_passenger_path(reservation, id: passenger_student.id, model: 'student', recurring: '')
      end.to change { reservation.reload.passengers.count }.by(1)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(add_drivers_and_passengers_path(reservation, edit: nil, recurring: ''))
      expect(reservation.reload.passengers).to include(passenger_student)
    end

    it 'removes a student passenger via turbo stream' do
      reservation.passengers << passenger_student

      expect do
        delete remove_passenger_path(reservation, passenger_student, 'student', format: :turbo_stream), params: { recurring: '' }
      end.to change { reservation.reload.passengers.count }.by(-1)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(reservation.reload.passengers).not_to include(passenger_student)
    end

    it 'promotes a student passenger to driver via turbo stream' do
      reservation.passengers << passenger_student

      get make_driver_path(reservation, passenger_student, 'student', format: :turbo_stream), params: { recurring: '' }
      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(reservation.reload.driver_id).to eq(passenger_student.id)
      expect(reservation.reload.passengers).to include(driver_student)
      expect(reservation.reload.passengers).not_to include(passenger_student)
    end
  end

  context 'with manager role' do
    let!(:manager_user) { FactoryBot.create(:user) }
    let!(:manager) do
      FactoryBot.create(
        :manager,
        uniqname: manager_user.uniqname,
        mvr_status: 'Approved until 2030-12-31',
        phone_number: '734-000-0010'
      )
    end
    let!(:manager_reservation) do
      FactoryBot.create(
        :reservation,
        program: program,
        site: site,
        car: car,
        driver_manager: manager,
        reserved_by: manager_user.id,
        updated_by: manager_user.id,
        number_of_people_on_trip: 4
      )
    end

    before do
      stub_non_admin_access(manager_user)
      mock_login(manager_user)
    end

    it 'allows manager in reservation to view add_drivers_and_passengers' do
      get add_drivers_and_passengers_path(manager_reservation)

      expect(response).to have_http_status(200)
    end

    it 'allows manager in reservation to add a student passenger' do
      expect do
        get add_passenger_path(manager_reservation, id: other_student.id, model: 'student', recurring: '')
      end.to change { manager_reservation.reload.passengers.count }.by(1)

      expect(response).to have_http_status(302)
      expect(manager_reservation.reload.passengers).to include(other_student)
    end

    it 'currently allows manager not in reservation to view add_drivers_and_passengers' do
      outsider_user = FactoryBot.create(:user)
      FactoryBot.create(:manager, uniqname: outsider_user.uniqname)
      stub_non_admin_access(outsider_user)
      mock_login(outsider_user)

      get add_drivers_and_passengers_path(manager_reservation)

      expect(response).to have_http_status(200)
    end
  end

  context 'with student role' do
    let!(:student_user) { FactoryBot.create(:user) }
    let!(:self_student) do
      FactoryBot.create(
        :student,
        uniqname: student_user.uniqname,
        program: program,
        mvr_status: 'Approved until 2030-12-31',
        phone_number: '734-000-0020'
      )
    end
    let!(:student_reservation) do
      FactoryBot.create(
        :reservation,
        program: program,
        site: site,
        car: car,
        driver: self_student,
        reserved_by: student_user.id,
        updated_by: student_user.id,
        number_of_people_on_trip: 4
      )
    end

    before do
      stub_non_admin_access(student_user)
      mock_login(student_user)
    end

    it 'allows student in reservation to view add_drivers_and_passengers' do
      get add_drivers_and_passengers_path(student_reservation)

      expect(response).to have_http_status(200)
    end

    it 'allows student in reservation to add a student passenger' do
      expect do
        get add_passenger_path(student_reservation, id: other_student.id, model: 'student', recurring: '')
      end.to change { student_reservation.reload.passengers.count }.by(1)

      expect(response).to have_http_status(302)
      expect(student_reservation.reload.passengers).to include(other_student)
    end
  end

  context 'with none role' do
    let!(:user) { FactoryBot.create(:user) }

    before do
      stub_non_admin_access(user)
      mock_login(user)
    end

    it 'is not authorized for add_drivers_and_passengers' do
      get add_drivers_and_passengers_path(reservation)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is not authorized for add_passenger' do
      expect do
        get add_passenger_path(reservation, id: passenger_student.id, model: 'student', recurring: '')
      end.not_to change { reservation.reload.passengers.count }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end
end
