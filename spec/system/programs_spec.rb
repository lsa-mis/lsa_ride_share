require 'rails_helper'

RSpec.describe Program, type: :system do

	before do
    load "#{Rails.root}/spec/test_seeds.rb" 
		user = FactoryBot.create(:user)
    allow(LdapLookup).to receive(:is_member_of_group?).with(anything, anything).and_return(true)
    allow(LdapLookup).to receive(:get_simple_name).with(anything).and_return(true)
		mock_login(user)
	end

	context "create new program" do
    it 'is valid input' do
      VCR.use_cassette "program" do
        unit = Unit.first
        uniqname = 'fakeuniqname'
        allow(LdapLookup).to receive(:is_member_of_group?).with(uniqname, anything).and_return(false)
        allow(LdapLookup).to receive(:uid_exist?).with(uniqname).and_return(true)
        allow(LdapLookup).to receive(:get_simple_name).with(uniqname).and_return("Rita Barvinok")

        visit programs_path
        click_on "New Program"
        
        fill_in "Title", with: "Fake Program"
        select "Fall 2024", from: "Term"
        fill_in "Instructor's uniqname", with: uniqname
        fill_in "Canvas Course Link", with: "link"
        fill_in "Canvas Course Number", with: "123"
        click_on "Create Program"
        expect(page).to have_content("Program was successfully created.")
      end
    end
  end

  context "edit a program" do
    it 'updates title' do
      VCR.use_cassette "program" do
        program = FactoryBot.create(:program, updated_by: User.last.id, term: Term.last, unit: Unit.last)
        visit "programs/#{program.id}/"
        click_on "Edit Program"
        fill_in "Title", with: "Edited Program Title"
        click_on "Update Program"
        expect(page).to have_content("Edited Program Title")
        expect(page).to have_content("Program was successfully updated.")
      end
    end
  end

end
