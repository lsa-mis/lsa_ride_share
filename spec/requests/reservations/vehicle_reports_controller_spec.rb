require 'rails_helper'

RSpec.describe Reservations::VehicleReportsController, type: :request do
  let!(:unit) { FactoryBot.create(:unit) }
  let!(:term) { FactoryBot.create(:term) }
  let!(:instructor) { FactoryBot.create(:manager) }
  let!(:program) { FactoryBot.create(:program, unit: unit, term: term, instructor: instructor) }
  let!(:site) { FactoryBot.create(:site, unit: unit) }
  let!(:car) { FactoryBot.create(:car, unit: unit, parking_spot: 'Lot A', gas: 40, mileage: 1000) }

  let!(:driver_student) do
    FactoryBot.create(
      :student,
      program: program,
      mvr_status: 'Approved until 2030-12-31',
      phone_number: '734-000-1000'
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
      updated_by: reservation_owner.id
    )
  end

  let!(:parking_pref) do
    UnitPreference.create!(
      name: 'parking_location',
      description: 'Parking location list',
      value: 'Lot A,Lot B,Other',
      pref_type: :string,
      unit: unit
    )
  end

  context 'with admin role' do
    let!(:admin_user) { FactoryBot.create(:user) }

    before do
      stub_admin_access(admin_user, unit)
      mock_login(admin_user)
    end

    it 'returns 200 for nested new' do
      get new_reservation_vehicle_report_path(reservation)

      expect(response).to have_http_status(200)
      expect(response.body).to include('New Vehicle Report')
      expect(response.body).to include('Lot A')
    end

    it 'creates a vehicle report through nested route and redirects to show' do
      expect do
        post reservation_vehicle_reports_path(reservation), params: {
          vehicle_report: {
            reservation_id: reservation.id,
            mileage_start: 2000,
            mileage_end: 2010,
            gas_start: 65,
            gas_end: 55,
            parking_spot: 'Lot A',
            parking_note: 'start note',
            parking_note_return: 'return note',
            created_by: admin_user.id,
            updated_by: admin_user.id
          },
          parking_spot_return: 'Lot B'
        }
      end.to change(VehicleReport, :count).by(1)

      created = VehicleReport.last
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(vehicle_report_path(created))
      expect(created.reservation_id).to eq(reservation.id)
      expect(created.car_id).to eq(car.id)
      expect(created.parking_spot_return).to eq('Lot B')
    end
  end

  context 'with manager role' do
    let!(:manager_user) { FactoryBot.create(:user) }
    let!(:manager) do
      FactoryBot.create(
        :manager,
        uniqname: manager_user.uniqname,
        mvr_status: 'Approved until 2030-12-31',
        phone_number: '734-000-1001'
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
        updated_by: manager_user.id
      )
    end

    before do
      stub_non_admin_access(manager_user)
      mock_login(manager_user)
    end

    it 'allows nested new when manager is reservation driver' do
      get new_reservation_vehicle_report_path(manager_reservation)

      expect(response).to have_http_status(200)
    end

    it 'blocks nested new for manager not involved in reservation' do
      outsider_user = FactoryBot.create(:user)
      FactoryBot.create(:manager, uniqname: outsider_user.uniqname)
      stub_non_admin_access(outsider_user)
      mock_login(outsider_user)

      get new_reservation_vehicle_report_path(reservation)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_manager_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end

  context 'with student role' do
    let!(:student_user) { FactoryBot.create(:user) }
    let!(:student) do
      FactoryBot.create(
        :student,
        uniqname: student_user.uniqname,
        program: program,
        mvr_status: 'Approved until 2030-12-31',
        phone_number: '734-000-1002'
      )
    end
    let!(:student_reservation) do
      FactoryBot.create(
        :reservation,
        program: program,
        site: site,
        car: car,
        driver: student,
        reserved_by: student_user.id,
        updated_by: student_user.id
      )
    end

    before do
      stub_non_admin_access(student_user)
      mock_login(student_user)
    end

    it 'allows nested create when student is reservation driver' do
      expect do
        post reservation_vehicle_reports_path(student_reservation), params: {
          vehicle_report: {
            reservation_id: student_reservation.id,
            mileage_start: 123,
            mileage_end: 133,
            gas_start: 65,
            gas_end: 60,
            parking_spot: 'Lot A',
            created_by: student_user.id,
            updated_by: student_user.id
          },
          parking_spot_return: 'Lot B'
        }
      end.to change(VehicleReport, :count).by(1)

      expect(response).to have_http_status(302)
      expect(VehicleReport.last.reservation_id).to eq(student_reservation.id)
    end
  end

  context 'with none role' do
    let!(:user) { FactoryBot.create(:user) }

    before do
      stub_non_admin_access(user)
      mock_login(user)
    end

    it 'is not authorized for nested new' do
      get new_reservation_vehicle_report_path(reservation)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end
end
