require 'rails_helper'

RSpec.describe Car, type: :system do

	before do
		user = FactoryBot.create(:user)
		# unit = FactoryBot.create(:unit)
    # binding.pry
		# allow(LdapLookup).to receive(:is_member_of_group?).with(anything, "lsa-was-rails-devs").and_return(true)
    allow(LdapLookup).to receive(:is_member_of_group?).with(anything, anything).and_return(true)

    # allow_any_instance_of(User).to receive(:unit.id).and_return([unit.id])
		mock_login(user)
	end

	context "create new car" do
    it 'is valid input' do
      VCR.use_cassette "zone" do
        visit cars_path
        click_on "New Car"
        binding.pry
        select unit.name, from: "Unit"
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

end
