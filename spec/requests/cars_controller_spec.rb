require 'rails_helper'

RSpec.describe Car, type: :request do
  let!(:unit) { FactoryBot.create(:unit) }
  let!(:car) { FactoryBot.create(:car, unit: unit) }

  def create_parking_pref(for_unit, value = 'Thayer 1A, Thayer 1B')
    FactoryBot.create(
      :unit_preference,
      unit: for_unit,
      name: 'parking_location',
      description: 'Parking locations for cars',
      pref_type: :string,
      value: value
    )
  end

  context 'with super_admin role' do
    let!(:super_admin_user) { FactoryBot.create(:user) }

    before do
      create_parking_pref(unit)
      stub_super_admin_access(super_admin_user, unit)
      mock_login(super_admin_user)
    end

    it 'returns 200 for index' do
      get cars_path
      expect(response).to have_http_status(200)
    end

    it 'returns 200 for show' do
      get car_path(car)
      expect(response).to have_http_status(200)
    end
  end

  context 'with admin role' do
    let!(:admin_user) { FactoryBot.create(:user) }

    before do
      create_parking_pref(unit)
      stub_admin_access(admin_user)
      mock_login(admin_user)
    end

    it 'returns 200 for new' do
      get new_car_path
      expect(response).to have_http_status(200)
    end

    it 'creates a car and redirects to show page' do
      car_params = {
        car_number: 'ADMIN-001',
        make: 'Ford',
        model: 'Fusion',
        color: 'White',
        number_of_seats: 5,
        mileage: 12345,
        gas: 50.0,
        parking_spot: 'Old Spot',
        status: 'available',
        unit_id: unit.id,
        updated_by: admin_user.id
      }

      expect do
        post cars_path, params: {
          car: car_params,
          parking_spot_select: 'Thayer 1A'
        }
      end.to change(Car, :count).by(1)

      expect(response).to redirect_to(car_path(Car.last))
      expect(Car.last.parking_spot).to eq('Thayer 1A')
    end

    it 'returns 200 for edit' do
      get edit_car_path(car)
      expect(response).to have_http_status(200)
    end

    it 'updates a car and redirects to show page' do
      patch car_path(car), params: {
        car: {
          car_number: car.car_number,
          make: car.make,
          model: car.model,
          color: car.color,
          number_of_seats: car.number_of_seats,
          mileage: car.mileage,
          gas: car.gas,
          parking_spot: car.parking_spot,
          status: 'unavailable',
          unit_id: car.unit_id,
          updated_by: admin_user.id
        },
        parking_spot_select: 'Other',
        parking_spot: 'North Lot'
      }

      expect(response).to redirect_to(car_path(car))
      expect(car.reload.status).to eq('unavailable')
      expect(car.reload.parking_spot).to eq('North Lot')
    end

    it 'returns parking locations JSON' do
      get "/cars/get_parking_locations/#{unit.id}"

      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)).to eq(['Thayer 1A', 'Thayer 1B'])
    end
  end

  context 'with manager role' do
    let!(:manager_user) { FactoryBot.create(:user) }
    let!(:manager) { FactoryBot.create(:manager, uniqname: manager_user.uniqname) }
    let!(:program) { FactoryBot.create(:program, unit: unit, instructor: manager) }

    before do
      stub_non_admin_access(manager_user)
      mock_login(manager_user)
    end

    it 'is not authorized for index and redirects to manager page' do
      get cars_path
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_manager_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is authorized for show' do
      get car_path(car)
      expect(response).to have_http_status(200)
    end

    it 'is not authorized for get_parking_locations' do
      create_parking_pref(unit)
      get "/cars/get_parking_locations/#{unit.id}"

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_manager_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end

  context 'with student role' do
    let!(:instructor_user) { FactoryBot.create(:user) }
    let!(:instructor) { FactoryBot.create(:manager, uniqname: instructor_user.uniqname) }
    let!(:program) { FactoryBot.create(:program, unit: unit, instructor: instructor) }
    let!(:student_user) { FactoryBot.create(:user) }
    let!(:student) { FactoryBot.create(:student, uniqname: student_user.uniqname, program: program) }

    before do
      stub_non_admin_access(student_user)
      mock_login(student_user)
    end

    it 'is not authorized for index and redirects to student page' do
      get cars_path
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_student_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is authorized for show' do
      get car_path(car)
      expect(response).to have_http_status(200)
    end
  end

  context 'with none role' do
    let!(:user) { FactoryBot.create(:user) }

    before do
      stub_non_admin_access(user)
      mock_login(user)
    end

    it 'is not authorized for index and redirects to root' do
      get cars_path
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is not authorized for show and redirects to root' do
      get car_path(car)
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end
end
