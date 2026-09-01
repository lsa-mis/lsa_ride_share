require 'rails_helper'

RSpec.describe NotesController, type: :request do
  let!(:unit) { FactoryBot.create(:unit) }
  let!(:site) { FactoryBot.create(:site, unit: unit) }
  let!(:note_owner) { FactoryBot.create(:user) }
  let!(:note) { Note.create!(user: note_owner, noteable: site, body: 'Initial note body') }

  context 'with admin role' do
    let!(:admin_user) { FactoryBot.create(:user) }

    before do
      stub_admin_access(admin_user, unit)
      mock_login(admin_user)
    end

    it 'updates a note and sets current user as updater' do
      patch note_path(note), params: {
        note: {
          body: 'Updated note body'
        }
      }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(note_path(note))
      expect(note.reload.user_id).to eq(admin_user.id)
      expect(note.body.to_plain_text).to include('Updated note body')
    end

    it 'destroys a note and redirects to noteable page' do
      expect do
        delete note_path(note)
      end.to change(Note, :count).by(-1)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(site_path(site))
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

    it 'is not authorized to update a note' do
      patch note_path(note), params: {
        note: {
          body: 'Unauthorized update'
        }
      }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_manager_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is not authorized to destroy a note' do
      expect do
        delete note_path(note)
      end.not_to change(Note, :count)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_manager_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end

  context 'with student role' do
    let!(:student_user) { FactoryBot.create(:user) }
    let!(:instructor) { FactoryBot.create(:manager) }
    let!(:term) { FactoryBot.create(:term) }
    let!(:program) { FactoryBot.create(:program, unit: unit, term: term, instructor: instructor) }
    let!(:student) { FactoryBot.create(:student, uniqname: student_user.uniqname, program: program) }

    before do
      student
      stub_non_admin_access(student_user)
      mock_login(student_user)
    end

    it 'is not authorized to update a note' do
      patch note_path(note), params: {
        note: {
          body: 'Unauthorized student update'
        }
      }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_student_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is not authorized to destroy a note' do
      expect do
        delete note_path(note)
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

    it 'is not authorized to update a note' do
      patch note_path(note), params: {
        note: {
          body: 'Unauthorized none-role update'
        }
      }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is not authorized to destroy a note' do
      expect do
        delete note_path(note)
      end.not_to change(Note, :count)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end
end
