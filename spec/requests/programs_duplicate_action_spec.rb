require 'rails_helper'

SUPER_ADMIN_LDAP_GROUP = "lsa-was-rails-devs"

RSpec.describe Program, type: :request do

  context 'duplicate action' do
    let!(:unit) { FactoryBot.create(:unit) }
    let!(:program) { FactoryBot.create(:program, unit: unit) }

    context 'with super_admin role' do
      let!(:super_admin_user) { FactoryBot.create(:user) }

      before do
        # make a user a member of the SUPER_ADMIN_LDAP_GROUP group
        allow(LdapLookup).to receive(:is_member_of_group?).with(super_admin_user.uniqname, SUPER_ADMIN_LDAP_GROUP).and_return(true)
        allow(LdapLookup).to receive(:is_member_of_group?).with(super_admin_user.uniqname, unit.ldap_group).and_return(false)
        mock_login(super_admin_user)
      end

      it 'goes to duplicate path and returns 200' do
        get duplicate_path(program)
        # binding.pry
        # expect {
        #   get duplicate_path(program)
        # }.to change { Program.count }.by(1)
        expect(response).to render_template(:new)
        # expect(response).to have_http_status(200)
      end

      it 'goes to duplicate path and returns 200' do
        # visit duplicate_path(program)
        # click_button 'Submit'
        expect {
          visit duplicate_path(program)
          click_button 'Submit'
        }.to change { Program.count }.by(1)
        expect(page).to have_http_status(200)
      end

    end

    context 'with admin role' do
      let!(:admin_user) { FactoryBot.create(:user) }
      let!(:unit) { FactoryBot.create(:unit) }

      before do
        # make a user a member of the SUPER_ADMIN_LDAP_GROUP group
        allow(LdapLookup).to receive(:is_member_of_group?).with(admin_user.uniqname, SUPER_ADMIN_LDAP_GROUP).and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(admin_user.uniqname, unit.ldap_group).and_return(true)
        mock_login(admin_user)
      end

      it 'returns 200' do
      end
    end

    context 'with manager who has a program' do
      let!(:user_manager) { FactoryBot.create(:user) }
      let!(:manager) { FactoryBot.create(:manager, uniqname: user_manager.uniqname) }
      let!(:program) { FactoryBot.create(:program, instructor: manager) }

      before do
      end

      it 'returns 200' do
        get programs_path
        expect(response).to have_http_status(200)
      end
    end

    context 'with manager who has no programs' do
      let!(:user_manager) { FactoryBot.create(:user) }
      let!(:manager) { FactoryBot.create(:manager, uniqname: user_manager.uniqname) }

      before do
        allow(LdapLookup).to receive(:is_member_of_group?).with(anything, SUPER_ADMIN_LDAP_GROUP).and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(user_manager.uniqname, anything).and_return(false)
        mock_login(user_manager)
      end

      it 'returns 302' do
      end

    end

    context 'with student who has a currrent term program' do
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

      it 'returns 302' do
      end

    end

    context 'with "none" role who has no currrent term programs' do
      let!(:user) { FactoryBot.create(:user) }

      before do
        allow(LdapLookup).to receive(:is_member_of_group?).with(anything, SUPER_ADMIN_LDAP_GROUP).and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(user.uniqname, anything).and_return(false)
        mock_login(user)
      end

      it 'returns 302, redirects to root and displayes alert message' do
      end
    end

  end
end
