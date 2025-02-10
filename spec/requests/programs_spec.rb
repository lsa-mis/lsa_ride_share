require 'rails_helper'

SUPER_ADMIN_LDAP_GROUP = "lsa-was-rails-devs"

def define_group_membership(user, ldap_group, membership)
  allow(LdapLookup).to receive(:is_member_of_group?).with(user.uniqname, ldap_group).and_return(membership)
end

RSpec.describe Program, type: :request do

  context 'index action' do

    context 'with super_admin role' do
      let!(:super_admin_user) { FactoryBot.create(:user) }
      let!(:unit) { FactoryBot.create(:unit) }

      before do
        # make a user a member of the SUPER_ADMIN_LDAP_GROUP group
        allow(LdapLookup).to receive(:is_member_of_group?).with(super_admin_user.uniqname, SUPER_ADMIN_LDAP_GROUP).and_return(true)
        allow(LdapLookup).to receive(:is_member_of_group?).with(super_admin_user.uniqname, unit.ldap_group).and_return(false)
        # define_group_membership(super_admin_user, SUPER_ADMIN_LDAP_GROUP, true)
        # define_group_membership(super_admin_user, unit.ldap_group, false)
        mock_login(super_admin_user)
      end

      it 'returns 200' do
        get programs_path
        # binding.pry
        expect(response).to have_http_status(200)
      end
    end

    context 'with admin role' do
      let!(:admin_user) { FactoryBot.create(:user) }
      let!(:unit) { FactoryBot.create(:unit) }

      it 'returns 200' do
        allow(LdapLookup).to receive(:is_member_of_group?).with(admin_user.uniqname, SUPER_ADMIN_LDAP_GROUP).and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(admin_user.uniqname, unit.ldap_group).and_return(true)
        # define_group_membership(admin_user, SUPER_ADMIN_LDAP_GROUP, false)
        # define_group_membership(admin_user, unit.ldap_group, true)
        mock_login(admin_user)
        get programs_path
        expect(response).to have_http_status(200)
      end
    end

    context 'with manager who has a program' do
      let!(:user_manager) { FactoryBot.create(:user) }
      let!(:manager) { FactoryBot.create(:manager, uniqname: user_manager.uniqname) }
      let!(:program) { FactoryBot.create(:program, instructor: manager) }

      it 'returns 200' do
        allow(LdapLookup).to receive(:is_member_of_group?).with(anything, SUPER_ADMIN_LDAP_GROUP).and_return(false)
        allow(LdapLookup).to receive(:is_member_of_group?).with(user_manager.uniqname, anything).and_return(false)
        # define_group_membership(user_manager, SUPER_ADMIN_LDAP_GROUP, false)
        # define_group_membership(user_manager, anything, false)
        mock_login(user_manager)
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
        get programs_path
        expect(response).to have_http_status(302)
      end

      it 'redirects to welcome manager page' do
        get programs_path
        expect(response.location).to include("/welcome_pages/manager")
      end

      it 'displayes alert message' do
        get programs_path
        expect(flash[:alert]).to match("You are not authorized to perform this action.")
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
        get programs_path
        expect(response).to have_http_status(302)
      end

      it 'redirects to welcome student page' do
        get programs_path
        expect(response.location).to include("/welcome_pages/student")
      end

      it 'displayes alert message' do
        get programs_path
        expect(flash[:alert]).to match("You are not authorized to perform this action.")
      end
    end

    context 'with "none" role who has no currrent term programs' do
      let!(:user) { FactoryBot.create(:user) }

      it 'returns 302, redirects to root and displayes alert message' do
        # allow(LdapLookup).to receive(:is_member_of_group?).with(anything, SUPER_ADMIN_LDAP_GROUP).and_return(false)
        # allow(LdapLookup).to receive(:is_member_of_group?).with(user.uniqname, anything).and_return(false)
        define_group_membership(user, SUPER_ADMIN_LDAP_GROUP, false)
        define_group_membership(user, anything, false)
        mock_login(user)
        get programs_path
        expect(response).to have_http_status(302)
        # expect(response.location).to redirect_to("/")
        expect(response).to redirect_to("/")
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end

    context 'with super_admin role' do
      let!(:user) { FactoryBot.create(:user) }
      let!(:program) { FactoryBot.create(:program) }

      before do
        allow(LdapLookup).to receive(:is_member_of_group?).with(user.uniqname, SUPER_ADMIN_LDAP_GROUP).and_return(true)
        allow(LdapLookup).to receive(:is_member_of_group?).with(user.uniqname, Unit.first.ldap_group).and_return(false)
        mock_login(user)
      end

      it 'should display Edit and Duplicate buttons in a program card' do
        get programs_path
        expect(response.body).to include("Edit")
        expect(response.body).to include("Duplicate")
      end
    end

    context 'with admin role' do
      let!(:user) { FactoryBot.create(:user) }
      let!(:program) { FactoryBot.create(:program) }

      it 'should display Edit and Duplicate buttons in a program card' do
        # allow(LdapLookup).to receive(:is_member_of_group?).with(user.uniqname, SUPER_ADMIN_LDAP_GROUP).and_return(false)
        # allow(LdapLookup).to receive(:is_member_of_group?).with(user.uniqname, Unit.first.ldap_group).and_return(true)
        define_group_membership(user, SUPER_ADMIN_LDAP_GROUP, false)
        define_group_membership(user, Unit.first.ldap_group, true)
        mock_login(user)
        get programs_path
        expect(response.body).to include("Edit")
        expect(response.body).to include("Duplicate")
      end
    end

    context 'with manager role' do
      let!(:user_manager) { FactoryBot.create(:user) }
      let!(:manager) { FactoryBot.create(:manager, uniqname: user_manager.uniqname) }
      let!(:program) { FactoryBot.create(:program, instructor: manager) }

      it 'should display Edit but no Duplicate button in a program card' do
        # allow(LdapLookup).to receive(:is_member_of_group?).with(user_manager.uniqname, SUPER_ADMIN_LDAP_GROUP).and_return(false)
        # allow(LdapLookup).to receive(:is_member_of_group?).with(user_manager.uniqname, Unit.first.ldap_group).and_return(false)
        define_group_membership(user_manager, SUPER_ADMIN_LDAP_GROUP, false)
        define_group_membership(user_manager, Unit.first.ldap_group, false)
        mock_login(user_manager)
        get programs_path
        expect(response.body).to include("Edit")
        expect(response.body).not_to include("Duplicate")
      end
    end

  end
end
