require 'rails_helper'

RSpec.describe Program, type: :system do

	before do
    load "#{Rails.root}/spec/test_seeds.rb" 
		user = FactoryBot.create(:user)
    allow(LdapLookup).to receive(:is_member_of_group?).with(anything, "lsa-was-rails-devs").and_return(false)
    allow(LdapLookup).to receive(:is_member_of_group?).with(user.uniqname, Unit.first.ldap_group).and_return(true)
		mock_login(user)
	end

	context "create new program" do
    it 'is valid input' do
      unit = Unit.first
      uniqname = 'fakeuniqname'
      # uniqname is not a member of any admin groups
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

  context "edit a program" do
    it 'updates title' do
      program = FactoryBot.create(:program, updated_by: User.last.id, term: Term.last, unit: Unit.last)
      visit "programs/#{program.id}/"
      click_on "Edit Program"
      fill_in "Title", with: "Edited Program Title"
      click_on "Update Program"
      expect(page).to have_content("Edited Program Title")
      expect(page).to have_content("Program was successfully updated.")
    end
  end

  context "add associated courses to a program" do
    it 'succeed with valid input' do
      program = FactoryBot.create(:program, updated_by: User.last.id, term: Term.last, unit: Unit.last)
      visit "programs/#{program.id}/"
      click_on "Add Associated Courses"
      expect(page).to have_content("Update Courses for Program")
      fill_in "Subject", with: "Course One"
      fill_in "Catalog Number", with: "123"
      fill_in "Class Section", with: "001"
      click_on "Add New Course"
      expect(page).to have_content("Course list is updated.")
    end
  end

  context "add associated courses to a program" do
    it 'fails with duplicated course data' do
      program = FactoryBot.create(:program, updated_by: User.last.id, term: Term.last, unit: Unit.last)
      course = FactoryBot.create(:course, program: program)
      visit "programs/#{program.id}/"
      click_on "Edit Associated Courses"
      expect(page).to have_content("Update Courses for Program")
      fill_in "Subject", with: course.subject
      fill_in "Catalog Number", with: course.catalog_number
      fill_in "Class Section", with: course.class_section
      click_on "Add New Course"
      expect(page).to have_content("Program already has this course")
    end
  end

end
