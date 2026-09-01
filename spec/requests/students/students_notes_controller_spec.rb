require 'rails_helper'

RSpec.describe Students::NotesController, type: :request do
  let!(:unit) { FactoryBot.create(:unit) }
  let!(:term) { FactoryBot.create(:term) }
  let!(:instructor) { FactoryBot.create(:manager) }
  let!(:program) { FactoryBot.create(:program, unit: unit, term: term, instructor: instructor) }
  let!(:student_record) { FactoryBot.create(:student, program: program) }

  context 'with admin role' do
    let!(:admin_user) { FactoryBot.create(:user) }

    before do
      stub_admin_access(admin_user, unit)
      mock_login(admin_user)
    end

    it 'creates a note and redirects to student page for html requests' do
      expect do
        post student_notes_path(student_record), params: {
          note: {
            body: 'Admin note for student'
          }
        }
      end.to change(Note, :count).by(1)

      created_note = Note.last
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(student_path(student_record))
      expect(created_note.noteable).to eq(student_record)
      expect(created_note.user_id).to eq(admin_user.id)
      expect(created_note.body.to_plain_text).to include('Admin note for student')
    end

    it 'creates a note and responds with turbo stream' do
      expect do
        post student_notes_path(student_record, format: :turbo_stream), params: {
          note: {
            body: 'Turbo note for student'
          }
        }
      end.to change(Note, :count).by(1)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
    end

    it 'does not create a note when body is blank and redirects to student page' do
      expect do
        post student_notes_path(student_record), params: {
          note: {
            body: ''
          }
        }
      end.not_to change(Note, :count)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(student_path(student_record))
    end
  end

  context 'with manager role' do
    let!(:manager_user) { FactoryBot.create(:user) }
    let!(:manager) { FactoryBot.create(:manager, uniqname: manager_user.uniqname) }

    before do
      manager
      stub_non_admin_access(manager_user)
      mock_login(manager_user)
    end

    it 'is not authorized to create a note' do
      expect do
        post student_notes_path(student_record), params: {
          note: {
            body: 'Manager note attempt'
          }
        }
      end.not_to change(Note, :count)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_manager_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end

  context 'with student role' do
    let!(:student_user) { FactoryBot.create(:user) }
    let!(:self_student) { FactoryBot.create(:student, uniqname: student_user.uniqname, program: program) }

    before do
      self_student
      stub_non_admin_access(student_user)
      mock_login(student_user)
    end

    it 'is not authorized to create a note' do
      expect do
        post student_notes_path(student_record), params: {
          note: {
            body: 'Student note attempt'
          }
        }
      end.not_to change(Note, :count)

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

    it 'is not authorized to create a note' do
      expect do
        post student_notes_path(student_record), params: {
          note: {
            body: 'None-role note attempt'
          }
        }
      end.not_to change(Note, :count)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end
end
