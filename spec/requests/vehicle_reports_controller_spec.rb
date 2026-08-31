require 'rails_helper'

RSpec.describe VehicleReport, type: :request do
  let!(:unit) { FactoryBot.create(:unit) }
  let!(:term) { FactoryBot.create(:term) }
  let!(:instructor) { FactoryBot.create(:manager) }
  let!(:program) { FactoryBot.create(:program, unit: unit, term: term, instructor: instructor) }
  let!(:site) { FactoryBot.create(:site, unit: unit) }
  let!(:car) { FactoryBot.create(:car, unit: unit, parking_spot: 'Lot A', gas: 40, mileage: 1000) }

  context 'with admin role' do
    let!(:admin_user) { FactoryBot.create(:user) }
    let!(:student_driver) { FactoryBot.create(:student, program: program) }
    let!(:reservation) do
      FactoryBot.create(
        :reservation,
        program: program,
        site: site,
        car: car,
        driver: student_driver,
        reserved_by: admin_user.id,
        updated_by: admin_user.id
      )
    end
    let!(:vehicle_report) do
      FactoryBot.create(
        :vehicle_report,
        reservation: reservation,
        mileage_start: 1000,
        mileage_end: 1012,
        gas_start: 70,
        gas_end: 65,
        parking_spot: 'Lot A',
        parking_spot_return: 'Lot B',
        created_by: admin_user.id,
        updated_by: admin_user.id
      )
    end

    before do
      stub_admin_access(admin_user, unit)
      mock_login(admin_user)
    end

    it 'returns 200 for index' do
      get vehicle_reports_path

      expect(response).to have_http_status(200)
      expect(response.body).to include('Vehicle Reports')
    end

    it 'returns 200 for show' do
      get vehicle_report_path(vehicle_report)

      expect(response).to have_http_status(200)
      expect(response.body).to include("Vehicle Report: #{vehicle_report.id}")
    end

    it 'creates a vehicle report and redirects to show' do
      new_reservation = FactoryBot.create(
        :reservation,
        program: program,
        site: site,
        car: car,
        driver: student_driver,
        reserved_by: admin_user.id,
        updated_by: admin_user.id
      )
      expect do
        post vehicle_reports_path, params: {
          vehicle_report: {
            reservation_id: new_reservation.id,
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
          parking_spot_return: 'Lot C'
        }
      end.to change(VehicleReport, :count).by(1)

      created = VehicleReport.last
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(vehicle_report_path(created))
      expect(created.parking_spot_return).to eq('Lot C')
      expect(car.reload.mileage).to eq(2010)
      expect(car.reload.gas.to_f).to eq(55.0)
      expect(car.reload.parking_spot).to eq('Lot C')
      expect(car.reload.last_driver_id).to eq(student_driver.id)
    end

    it 'fails cleanly for an invalid reservation_id without raising a server error' do
      expect do
        post vehicle_reports_path, params: {
          vehicle_report: {
            reservation_id: -1,
            mileage_start: 2000,
            mileage_end: 2010,
            gas_start: 65,
            gas_end: 55,
            parking_spot: 'Lot A',
            created_by: admin_user.id,
            updated_by: admin_user.id
          },
          parking_spot_return: 'Lot C'
        }
      end.not_to change(VehicleReport, :count)

      expect(response).to have_http_status(422)
    end

    it 'updates a vehicle report and redirects to show' do
      patch vehicle_report_path(vehicle_report), params: {
        vehicle_report: {
          reservation_id: reservation.id,
          mileage_start: 1000,
          mileage_end: 1025,
          gas_start: 70,
          gas_end: 45,
          parking_spot: 'Lot A',
          parking_note_return: 'updated return note',
          updated_by: admin_user.id
        },
        parking_spot_return: 'Lot D'
      }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(vehicle_report_path(vehicle_report))
      expect(vehicle_report.reload.mileage_end).to eq(1025)
      expect(vehicle_report.reload.parking_spot_return).to eq('Lot D')
      expect(car.reload.mileage).to eq(1025)
      expect(car.reload.gas.to_f).to eq(45.0)
      expect(car.reload.parking_spot).to eq('Lot D')
    end

    it 'destroys an unapproved vehicle report and redirects to index' do
      deletable_report = FactoryBot.create(
        :vehicle_report,
        reservation: FactoryBot.create(:reservation, program: program, site: site, car: car, driver: student_driver),
        approved: false,
        created_by: admin_user.id,
        updated_by: admin_user.id
      )

      expect do
        delete vehicle_report_path(deletable_report)
      end.to change(VehicleReport, :count).by(-1)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(vehicle_reports_path)
      expect(flash[:notice]).to eq('Vehicle report was canceled.')
    end

    it 'does not destroy an approved vehicle report' do
      vehicle_report.update!(approved: true)

      expect do
        delete vehicle_report_path(vehicle_report), params: { format: :turbo_stream }
      end.not_to change(VehicleReport, :count)

      expect(response).to have_http_status(200)
      expect(VehicleReport.find_by(id: vehicle_report.id)).to be_present
    end

    it 'downloads the vehicle damage form pdf' do
      get download_vehicle_damage_form_path

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('application/pdf')
    end
  end

  context 'with manager role' do
    let!(:manager_user) { FactoryBot.create(:user) }
    let!(:manager) { FactoryBot.create(:manager, uniqname: manager_user.uniqname) }
    let!(:manager_program) { FactoryBot.create(:program, unit: unit, term: term, instructor: manager, title: 'Manager Vehicle Program') }
    let!(:manager_reservation) do
      FactoryBot.create(
        :reservation,
        program: manager_program,
        site: site,
        car: car,
        driver_manager: manager,
        reserved_by: manager_user.id,
        updated_by: manager_user.id
      )
    end
    let!(:manager_vehicle_report) do
      FactoryBot.create(
        :vehicle_report,
        reservation: manager_reservation,
        mileage_start: 100,
        gas_start: 70,
        created_by: manager_user.id,
        updated_by: manager_user.id
      )
    end

    before do
      stub_non_admin_access(manager_user)
      mock_login(manager_user)
    end

    it 'is not authorized for index' do
      get vehicle_reports_path

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_manager_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is authorized for show when manager is involved in reservation' do
      get vehicle_report_path(manager_vehicle_report)

      expect(response).to have_http_status(200)
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
        updated_by: student_user.id
      )
    end
    let!(:student_vehicle_report) do
      FactoryBot.create(
        :vehicle_report,
        reservation: student_reservation,
        mileage_start: 111,
        gas_start: 60,
        created_by: student_user.id,
        updated_by: student_user.id
      )
    end

    before do
      stub_non_admin_access(student_user)
      mock_login(student_user)
    end

    it 'is not authorized for index' do
      get vehicle_reports_path

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_student_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is authorized for show when student is reservation driver' do
      get vehicle_report_path(student_vehicle_report)

      expect(response).to have_http_status(200)
    end
  end

  context 'with none role' do
    let!(:user) { FactoryBot.create(:user) }
    let!(:reservation) { FactoryBot.create(:reservation, program: program, site: site, car: car) }
    let!(:vehicle_report) { FactoryBot.create(:vehicle_report, reservation: reservation) }

    before do
      stub_non_admin_access(user)
      mock_login(user)
    end

    it 'is not authorized for show' do
      get vehicle_report_path(vehicle_report)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is not authorized for download_vehicle_damage_form' do
      get download_vehicle_damage_form_path

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end
end
