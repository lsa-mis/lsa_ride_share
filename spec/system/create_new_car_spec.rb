require 'rails_helper'

RSpec.describe Car, type: :system do

	before do
		user = FactoryBot.create(:user)
		unit = FactoryBot.create(:unit, name: "Psychology")
		allow_any_instance_of(User).to receive(:unit_ids).and_return([unit.id])
		mock_login(user)
	end

	context "create new car" do
    it 'is valid input' do
			visit new_car_path
			select "Psychology", from: "Unit"
			fill_in "Car Number", with: "12345"
			fill_in "Make", with: "Ford"
			fill_in "Model", with: "Fusion"
			fill_in "Color", with: "white"
			fill_in "Number of Seats", with: "5"
			fill_in "Mileage", with: "10000"
			select "50.0", from: "Percent of Fuel Remaining"
			fill_in "Parking Spot", with: "Tappan"
			click_on "Create Car"
      expect(page).to have_content("A new car was added.")
    end
  end

end