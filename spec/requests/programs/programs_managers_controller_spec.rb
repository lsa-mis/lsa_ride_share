require 'rails_helper'

RSpec.describe Manager, type: :request do
  let!(:unit) { FactoryBot.create(:unit) }
  let!(:term) { FactoryBot.create(:term) }
  let!(:instructor) { FactoryBot.create(:manager) }
  let!(:program) { FactoryBot.create(:program, unit: unit, term: term, instructor: instructor) }

  context 'with admin role' do
    let!(:admin_user) { FactoryBot.create(:user) }

    before do
      stub_admin_access(admin_user, unit)
      mock_login(admin_user)
    end

    it 'returns 200 for edit_program_managers' do
      get edit_program_managers_path(program.id)

      expect(response).to have_http_status(200)
      expect(response.body).to include('Edit Managers for')
    end

    it 'adds an existing manager to the program via turbo stream' do
      manager_to_add = FactoryBot.create(:manager)

      expect do
        post program_managers_path(program, format: :turbo_stream), params: {
          manager_id: manager_to_add.id
        }
      end.to change(program.managers, :count).by(1)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(program.reload.managers).to include(manager_to_add)
    end

    it 'creates a new manager and adds to program via turbo stream' do
      allow_any_instance_of(Programs::ManagersController).to receive(:get_manager_name).and_return(
        { 'valid' => true, 'first_name' => 'New', 'last_name' => 'Manager', 'note' => '' }
      )

      expect do
        post program_managers_path(program, format: :turbo_stream), params: {
          manager: {
            uniqname: 'newmanager',
            first_name: '',
            last_name: '',
            program_id: program.id
          }
        }
      end.to change(Manager, :count).by(1)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(program.reload.managers.pluck(:uniqname)).to include('newmanager')
    end

    it 'removes a manager from program via turbo stream' do
      manager_to_remove = FactoryBot.create(:manager)
      program.managers << manager_to_remove

      delete remove_manager_from_program_path(program.id, manager_to_remove.id, format: :turbo_stream)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(program.reload.managers).not_to include(manager_to_remove)
    end
  end

  context 'with manager role' do
    let!(:manager_user) { FactoryBot.create(:user) }
    let!(:manager) { FactoryBot.create(:manager, uniqname: manager_user.uniqname) }
    let!(:manager_program) do
      FactoryBot.create(
        :program,
        unit: unit,
        term: term,
        instructor: manager,
        title: 'Manager Program'
      )
    end

    before do
      stub_non_admin_access(manager_user)
      mock_login(manager_user)
    end

    it 'is not authorized for edit_program_managers' do
      get edit_program_managers_path(manager_program.id)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_manager_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is not authorized for create' do
      post program_managers_path(manager_program, format: :turbo_stream), params: {
        manager: {
          uniqname: 'abc123',
          program_id: manager_program.id
        }
      }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_manager_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end

  context 'with student role' do
    let!(:student_user) { FactoryBot.create(:user) }
    let!(:student_record) { FactoryBot.create(:student, uniqname: student_user.uniqname, program: program) }

    before do
      stub_non_admin_access(student_user)
      mock_login(student_user)
    end

    it 'is not authorized for edit_program_managers' do
      get edit_program_managers_path(program.id)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_student_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is not authorized for remove_manager_from_program' do
      manager_to_remove = FactoryBot.create(:manager)
      program.managers << manager_to_remove

      delete remove_manager_from_program_path(program.id, manager_to_remove.id, format: :turbo_stream)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_student_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end
end
