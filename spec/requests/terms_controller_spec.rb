require 'rails_helper'

RSpec.describe Term, type: :request do
  let!(:term) { FactoryBot.create(:term) }

  context 'with super_admin role' do
    let!(:super_admin_user) { FactoryBot.create(:user) }
    let!(:unit) { FactoryBot.create(:unit) }

    before do
      stub_super_admin_access(super_admin_user, unit)
      mock_login(super_admin_user)
    end

    it 'returns 200 for index' do
      get terms_path
      expect(response).to have_http_status(200)
    end
  end

  context 'with admin role' do
    let!(:admin_user) { FactoryBot.create(:user) }
    let!(:unit) { FactoryBot.create(:unit) }

    before do
      stub_admin_access(admin_user, unit)
      mock_login(admin_user)
    end

    it 'returns 200 for index' do
      get terms_path
      expect(response).to have_http_status(200)
    end

    it 'returns 200 for show' do
      get term_path(term)
      expect(response).to have_http_status(200)
    end

    it 'returns 200 for new' do
      get new_term_path
      expect(response).to have_http_status(200)
    end

    it 'returns 200 for edit' do
      get edit_term_path(term)
      expect(response).to have_http_status(200)
    end

    it 'creates a term and redirects to show with notice' do
      expect do
        post terms_path, params: {
          term: {
            code: '3001',
            name: 'Future Term',
            classes_begin_date: Date.today + 30.days,
            classes_end_date: Date.today + 90.days
          }
        }
      end.to change(Term, :count).by(1)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(term_path(Term.last))
      expect(flash[:notice]).to eq('Term was successfully created.')
    end

    it 'does not create invalid term and returns 422' do
      expect do
        post terms_path, params: {
          term: {
            code: '',
            name: '',
            classes_begin_date: nil,
            classes_end_date: nil
          }
        }
      end.not_to change(Term, :count)

      expect(response).to have_http_status(422)
    end

    it 'updates a term and redirects to show with notice' do
      patch term_path(term), params: {
        term: {
          name: 'Updated Term Name'
        }
      }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(term_path(term))
      expect(flash[:notice]).to eq('Term was successfully updated.')
      expect(term.reload.name).to eq('Updated Term Name')
    end

    it 'destroys a term and redirects to index with notice' do
      term_to_delete = FactoryBot.create(:term, code: '3999', name: 'Delete Term')

      expect do
        delete term_path(term_to_delete)
      end.to change(Term, :count).by(-1)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(terms_path)
      expect(flash[:notice]).to eq('Term was successfully destroyed.')
    end
  end

  context 'with manager role' do
    let!(:manager_user) { FactoryBot.create(:user) }
    let!(:manager) { FactoryBot.create(:manager, uniqname: manager_user.uniqname) }
    let!(:program) { FactoryBot.create(:program, instructor: manager) }

    before do
      stub_non_admin_access(manager_user)
      mock_login(manager_user)
    end

    it 'is not authorized for index' do
      get terms_path
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_manager_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end

  context 'with student role' do
    let!(:instructor_user) { FactoryBot.create(:user) }
    let!(:instructor) { FactoryBot.create(:manager, uniqname: instructor_user.uniqname) }
    let!(:program) { FactoryBot.create(:program, instructor: instructor) }
    let!(:student_user) { FactoryBot.create(:user) }
    let!(:student) { FactoryBot.create(:student, uniqname: student_user.uniqname, program: program) }

    before do
      stub_non_admin_access(student_user)
      mock_login(student_user)
    end

    it 'is not authorized for index' do
      get terms_path
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
      get terms_path
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end
end
