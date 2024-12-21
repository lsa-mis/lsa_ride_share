require 'rails_helper'

RSpec.describe Car, type: :system do

	before do
    load "#{Rails.root}/spec/test_seeds.rb" 
		user = FactoryBot.create(:user)
    allow(LdapLookup).to receive(:is_member_of_group?).with(anything, "lsa-was-rails-devs").and_return(false)
    allow(LdapLookup).to receive(:is_member_of_group?).with(user.uniqname, Unit.first.ldap_group).and_return(true)
		mock_login(user)
	end

	context "create new car" do
    it 'is valid input' do
      unit = Unit.first
      visit cars_path
      click_on "New Car"
      fill_in "Car Number", with: "12345"
      fill_in "Make", with: "Ford"
      fill_in "Model", with: "Fusion"
      fill_in "Color", with: "white"
      fill_in "Number of Seats", with: "5"
      fill_in "Mileage", with: "10000"
      select "50.0", from: "Percent of Fuel Remaining"
      select "Thayer 1A", :from => "parking_spot_select"
      click_on "Create Car"
      expect(page).to have_content("A new car was added.")
    end
  end

  context "edit a car" do
    it 'updates parking location' do
      car = FactoryBot.create(:car, updated_by: User.last.id, unit: Unit.last)
      visit "cars/#{car.id}/"
      click_on "Edit Car"
      select "Thayer 1A", :from => "parking_spot_select"
      click_on "Update Car"
      expect(page).to have_content("Thayer 1A")
      expect(page).to have_content("The car was updated.")
    end
  end

end
