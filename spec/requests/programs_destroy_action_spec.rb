require 'rails_helper'

SUPER_ADMIN_LDAP_GROUP = "lsa-was-rails-devs"

RSpec.describe Program, type: :request do

  context 'destroy action' do
    let!(:unit) { FactoryBot.create(:unit) }
    let!(:program) { FactoryBot.create(:program, unit: unit) }

    context 'with super_admin role' do
      let!(:super_admin_user) { FactoryBot.create(:user) }

      before do
        # make the user a member of the SUPER_ADMIN_LDAP_GROUP group
        allow(LdapLookup).to receive(:is_member_of_group?).with(super_admin_user.uniqname, SUPER_ADMIN_LDAP_GROUP).and_return(true)
        allow(LdapLookup).to receive(:is_member_of_group?).with(super_admin_user.uniqname, unit.ldap_group).and_return(false)
        mock_login(super_admin_user)
      end

      it 'goes to delete path and deletes the program' do
        delete program_path(program)
        expect { Program.find(program.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'try to delete a program with active reservations and fail, show an error message, and not delete the program' do
        reservation = FactoryBot.create(:reservation, program: program)

        delete program_path(program)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(program_path(program))
        expect(flash[:alert]).to include("Program can't be deleted because it has active reservations")
        expect(Program.find(program.id)).to be_present
      end

      it 'try to delete a program with canceled reservations and succeed deleting the program' do
        reservation = FactoryBot.create(:reservation, program: program, canceled: true)

        delete program_path(program)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(programs_path)
        expect(flash[:notice]).to include("Program was successfully deleted.")
        expect { Program.find(program.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'try to delete a program with active and canceled reservations and fail, show an error message, and not delete the program' do
        active_reservation = FactoryBot.create(:reservation, program: program, canceled: false)
        canceled_reservation = FactoryBot.create(:reservation, program: program, canceled: true)

        delete program_path(program)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(program_path(program))
        expect(flash[:alert]).to include("Program can't be deleted because it has active reservations")
        expect(Program.find(program.id)).to be_present
      end

      it 'try to delete a program with sites and succeed' do
        site = FactoryBot.create(:site)
        program.sites << site
        delete program_path(program)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(programs_path)
        expect(flash[:notice]).to include("Program was successfully deleted.")
        expect { Program.find(program.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'try to delete a program with managers and succeed' do
        manager = FactoryBot.create(:manager)
        program.managers << manager
        delete program_path(program)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(programs_path)
        expect(flash[:notice]).to include("Program was successfully deleted.")
        expect { Program.find(program.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'try to delete a program that has courses and succeed' do
        course = FactoryBot.create(:course, program: program)
        student = FactoryBot.create(:student, program: program)
        course.students << student

        delete program_path(program)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(programs_path)
        expect(flash[:notice]).to include("Program was successfully deleted.")
        expect { Program.find(program.id) }.to raise_error(ActiveRecord::RecordNotFound)
        expect { Student.find(student.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'try to delete a program that has no courses, sites, or reservations and succeed' do
        delete program_path(program)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(programs_path)
        expect(flash[:notice]).to include("Program was successfully deleted.")
        expect { Program.find(program.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'try to delete a program that is associated with faculty-survey and succeed' do
        faculty_survey = FactoryBot.create(:faculty_survey, program_id: program.id)
        config_question = FactoryBot.create(:config_question, faculty_survey: faculty_survey)
        # Add answer content to the config question
        config_question.answer = "This is the answer content"
        config_question.save!

        delete program_path(program)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(programs_path)
        expect(flash[:notice]).to include("Program was successfully deleted.")
        expect { Program.find(program.id) }.to raise_error(ActiveRecord::RecordNotFound)
        expect(ConfigQuestion.find(config_question.id)).to be_present
        expect(FacultySurvey.find(faculty_survey.id)).to be_present
        expect(FacultySurvey.find(faculty_survey.id).program_id).to be_nil
        expect(ConfigQuestion.find(config_question.id).answer.body).to be_nil

      end

      it 'try to delete a program that fails deletion and show an error message' do
        allow_any_instance_of(Program).to receive(:destroy).and_return(false)
        allow_any_instance_of(Program).to receive_message_chain(:errors, :full_messages).and_return(["Error message 1", "Error message 2"])

        delete program_path(program)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(program_path(program))
        expect(flash[:alert]).to include("Program could not be deleted: Error message 1, Error message 2")
        expect(Program.find(program.id)).to be_present
      end

    end

    context 'with admin role' do
      let!(:admin_user) { FactoryBot.create(:user) }

      before do
        allow(LdapLookup).to receive(:is_member_of_group?).with(admin_user.uniqname, SUPER_ADMIN_LDAP_GROUP).and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(admin_user.uniqname, unit.ldap_group).and_return(true)
        mock_login(admin_user)
      end

      it 'is not authorized to delete a program and gets redirected with error message' do
        delete program_path(program)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(all_root_path)
        expect(flash[:alert]).to include("You are not authorized to perform this action")
      end

    end

    context 'with manager who has a program' do
      let!(:user_manager) { FactoryBot.create(:user) }
      let!(:manager) { FactoryBot.create(:manager, uniqname: user_manager.uniqname) }
      let!(:unit) { FactoryBot.create(:unit) }
      let!(:program) { FactoryBot.create(:program, unit: unit, instructor: manager) }

      before do
        # login with a manager role
        allow(LdapLookup).to receive(:is_member_of_group?).with(user_manager.uniqname, SUPER_ADMIN_LDAP_GROUP).and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(user_manager.uniqname, unit.ldap_group).and_return(false)
        mock_login(user_manager)
      end

      it 'is not authorized to delete a program and gets redirected with error message' do
        delete program_path(program)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(welcome_pages_manager_path)
        expect(flash[:alert]).to include("You are not authorized to perform this action")
      end

    end

    context 'with manager who has no programs' do
      let!(:user_manager) { FactoryBot.create(:user) }
      let!(:manager) { FactoryBot.create(:manager, uniqname: user_manager.uniqname) }
      let!(:unit) { FactoryBot.create(:unit) }

      before do
        allow(LdapLookup).to receive(:is_member_of_group?).with(user_manager.uniqname, SUPER_ADMIN_LDAP_GROUP).and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(user_manager.uniqname, unit.ldap_group).and_return(false)
        mock_login(user_manager)
      end

      it 'is not authorized to delete a program and gets redirected with error message' do
        delete program_path(program)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(welcome_pages_manager_path)
        expect(flash[:alert]).to include("You are not authorized to perform this action")
      end

    end

    context 'with student who has a current term program' do
      let!(:user_manager) { FactoryBot.create(:user) }
      let!(:manager) { FactoryBot.create(:manager, uniqname: user_manager.uniqname) }
      let!(:program) { FactoryBot.create(:program, instructor: manager) }
      let!(:user_student) { FactoryBot.create(:user) }
      let!(:student) { FactoryBot.create(:student, uniqname: user_student.uniqname, program: program) }

      before do
        allow(LdapLookup).to receive(:is_member_of_group?).with(anything, SUPER_ADMIN_LDAP_GROUP).and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(user_student.uniqname, anything).and_return(false)
        mock_login(user_student)
      end

      it 'is not authorized to delete a program and gets redirected with error message' do
        delete program_path(program)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(welcome_pages_student_path)
        expect(flash[:alert]).to include("You are not authorized to perform this action")
      end

    end

    context 'with "none" role who has no current term programs' do
      let!(:user) { FactoryBot.create(:user) }

      before do
        allow(LdapLookup).to receive(:is_member_of_group?).with(anything, SUPER_ADMIN_LDAP_GROUP).and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(user.uniqname, anything).and_return(false)
        mock_login(user)
      end

      it 'is not authorized to delete a program and gets redirected with error message' do
        delete program_path(program)
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(all_root_path)
        expect(flash[:alert]).to include("You are not authorized to perform this action")
      end
    end

  end
end
