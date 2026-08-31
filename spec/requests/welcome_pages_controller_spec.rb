require 'rails_helper'

RSpec.describe WelcomePagesController, type: :request do
  let!(:unit) { FactoryBot.create(:unit) }
  let!(:term) { FactoryBot.create(:term) }

  def create_welcome_unit_prefs(for_unit)
    FactoryBot.create(
      :unit_preference,
      unit: for_unit,
      name: 'hours_before_reservation',
      description: 'Hours before reservation',
      pref_type: :integer,
      value: '24'
    )
    FactoryBot.create(
      :unit_preference,
      unit: for_unit,
      name: 'send_reminders',
      description: 'Send reminders',
      pref_type: :boolean,
      on_off: false,
      value: ''
    )
    FactoryBot.create(
      :unit_preference,
      unit: for_unit,
      name: 'contact_phone',
      description: 'Contact phone',
      pref_type: :string,
      value: '734-000-0000'
    )
    FactoryBot.create(
      :unit_preference,
      unit: for_unit,
      name: 'unit_office',
      description: 'Unit office',
      pref_type: :string,
      value: '123 Test Building'
    )
    FactoryBot.create(
      :unit_preference,
      unit: for_unit,
      name: 'notification_email',
      description: 'Notification email',
      pref_type: :string,
      value: 'notify@example.com'
    )
  end

  context 'with student role' do
    let!(:student_user) { FactoryBot.create(:user) }
    let!(:instructor) { FactoryBot.create(:manager) }
    let!(:program) { FactoryBot.create(:program, unit: unit, term: term, instructor: instructor) }
    let!(:student) { FactoryBot.create(:student, uniqname: student_user.uniqname, program: program) }

    before do
      create_welcome_unit_prefs(unit)
      stub_non_admin_access(student_user)
      mock_login(student_user)
      allow_any_instance_of(WelcomePagesController).to receive(:mvr_status).and_return(
        { 'success' => true, 'mvr_status' => 'Approved until 2030-12-31' }
      )
    end

    it 'returns 200 for student welcome page' do
      get welcome_pages_student_path

      expect(response).to have_http_status(200)
      expect(response.body).to include('Welcome')
    end

    it 'returns 200 for edit student phone page' do
      get edit_student_phone_path(student.id), params: { frame_type: 'desktop' }

      expect(response).to have_http_status(200)
    end

    it 'updates student phone and redirects back' do
      post add_student_phone_path, params: {
        id: student.id,
        phone_number: '734-111-2222'
      }, headers: { 'HTTP_REFERER' => welcome_pages_student_path }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(/welcome_pages\/student/)
      expect(student.reload.phone_number).to eq('734-111-2222')
    end

    it 'is not authorized for manager welcome page' do
      get welcome_pages_manager_path

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_student_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end

  context 'with manager role' do
    let!(:manager_user) { FactoryBot.create(:user) }
    let!(:manager) { FactoryBot.create(:manager, uniqname: manager_user.uniqname) }
    let!(:program) { FactoryBot.create(:program, unit: unit, term: term, instructor: manager) }

    before do
      create_welcome_unit_prefs(unit)
      stub_non_admin_access(manager_user)
      mock_login(manager_user)
      allow_any_instance_of(WelcomePagesController).to receive(:mvr_status).and_return(
        { 'success' => true, 'mvr_status' => 'Approved until 2030-12-31' }
      )
    end

    it 'returns 200 for manager welcome page' do
      get welcome_pages_manager_path

      expect(response).to have_http_status(200)
      expect(response.body).to include('Welcome')
    end

    it 'returns 200 for edit manager phone page' do
      get edit_manager_phone_path(manager.id), params: { frame_type: 'desktop' }

      expect(response).to have_http_status(200)
    end

    it 'updates manager phone and redirects back' do
      post add_manager_phone_path, params: {
        id: manager.id,
        phone_number: '734-333-4444'
      }, headers: { 'HTTP_REFERER' => welcome_pages_manager_path }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(/welcome_pages\/manager/)
      expect(manager.reload.phone_number).to eq('734-333-4444')
    end

    it 'is not authorized for student welcome page' do
      get welcome_pages_student_path

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_manager_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end

  context 'with none role' do
    let!(:user) { FactoryBot.create(:user) }

    before do
      stub_non_admin_access(user)
      mock_login(user)
    end

    it 'is not authorized for student welcome page' do
      get welcome_pages_student_path

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end
end
