require 'rails_helper'

RSpec.describe Manager, type: :request do
  let!(:unit) { FactoryBot.create(:unit) }
  let!(:instructor) { FactoryBot.create(:manager) }
  let!(:program) { FactoryBot.create(:program, unit: unit, instructor: instructor) }

  def stub_super_admin_access(user, unit)
    allow(LdapLookup).to receive(:is_member_of_group?).with(user.uniqname, SUPER_ADMIN_LDAP_GROUP).and_return(true)
    allow(LdapLookup).to receive(:is_member_of_group?).with(user.uniqname, unit.ldap_group).and_return(false)
  end

  def stub_admin_access(user)
    allow(LdapLookup).to receive(:is_member_of_group?).with(anything, SUPER_ADMIN_LDAP_GROUP).and_return(false)
    allow(LdapLookup).to receive(:is_member_of_group?).with(user.uniqname, anything).and_return(true)
  end

  def stub_non_admin_access(user)
    allow(LdapLookup).to receive(:is_member_of_group?).with(anything, SUPER_ADMIN_LDAP_GROUP).and_return(false)
    allow(LdapLookup).to receive(:is_member_of_group?).with(user.uniqname, anything).and_return(false)
  end

  context 'with super_admin role' do
    let!(:super_admin_user) { FactoryBot.create(:user) }

    before do
      stub_super_admin_access(super_admin_user, unit)
      mock_login(super_admin_user)
    end

    it 'returns 200 for index' do
      get managers_path
      expect(response).to have_http_status(200)
    end

    it 'returns 200 for edit' do
      get edit_manager_path(instructor)
      expect(response).to have_http_status(200)
      expect(response.body).to include('Edit Manager')
    end

    it 'updates a manager and redirects to index' do
      patch manager_path(instructor), params: {
        manager: {
          uniqname: instructor.uniqname,
          first_name: 'UpdatedFirst',
          last_name: instructor.last_name,
          phone_number: '7341234567'
        },
        mvr_status: '2030-01-01'
      }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(managers_path)
      expect(instructor.reload.first_name).to eq('UpdatedFirst')
      expect(instructor.reload.mvr_status).to eq('Approved until 2030-01-01')
    end

    it 'deletes a manager and redirects to index' do
      manager_to_delete = FactoryBot.create(:manager)

      delete manager_path(manager_to_delete)
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(managers_path)
      expect { Manager.find(manager_to_delete.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'updates managers mvr status via turbo stream' do
      manager_in_program = FactoryBot.create(:manager)
      ManagersProgram.create!(manager: manager_in_program, program: program)

      allow_any_instance_of(ManagersController).to receive(:mvr_status).and_return(
        { 'success' => true, 'mvr_status' => 'Approved until 2030-12-31' }
      )

      get update_managers_mvr_status_path(format: :turbo_stream)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(manager_in_program.reload.mvr_status).to eq('Approved until 2030-12-31')
      expect(instructor.reload.mvr_status).to eq('Approved until 2030-12-31')
    end

    it 'shows alert when mvr status service fails' do
      allow_any_instance_of(ManagersController).to receive(:mvr_status).and_return(
        { 'success' => false, 'error' => 'service unavailable' }
      )

      get update_managers_mvr_status_path(format: :turbo_stream)

      expect(response).to have_http_status(200)
      expect(response.body).to include('Error retrieving MVR status')
    end
  end

  context 'with admin role' do
    let!(:admin_user) { FactoryBot.create(:user) }

    before do
      stub_admin_access(admin_user)
      mock_login(admin_user)
    end

    it 'returns 200 for index' do
      get managers_path
      expect(response).to have_http_status(200)
    end
  end

  context 'with manager role' do
    let!(:manager_user) { FactoryBot.create(:user) }
    let!(:manager) { FactoryBot.create(:manager, uniqname: manager_user.uniqname) }
    let!(:manager_program) { FactoryBot.create(:program, unit: unit, instructor: manager) }

    before do
      stub_non_admin_access(manager_user)
      mock_login(manager_user)
    end

    it 'is not authorized for index' do
      get managers_path
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_manager_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is not authorized for edit' do
      get edit_manager_path(instructor)
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_manager_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end

  context 'with student role' do
    let!(:student_user) { FactoryBot.create(:user) }
    let!(:student) { FactoryBot.create(:student, uniqname: student_user.uniqname, program: program) }

    before do
      stub_non_admin_access(student_user)
      mock_login(student_user)
    end

    it 'is not authorized for index' do
      get managers_path
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_student_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end

  context 'with none role' do
    let!(:user) { FactoryBot.create(:user) }

    before do
      stub_non_admin_access(user)
      mock_login(user)
    end

    it 'is not authorized for index' do
      get managers_path
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end
end
