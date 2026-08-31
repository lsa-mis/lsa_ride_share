require 'rails_helper'

RSpec.describe Site, type: :request do
  let!(:unit) { FactoryBot.create(:unit) }
  let!(:site) { FactoryBot.create(:site, unit: unit) }

  context 'with super_admin role' do
    let!(:super_admin_user) { FactoryBot.create(:user) }

    before do
      stub_super_admin_access(super_admin_user, unit)
      mock_login(super_admin_user)
    end

    it 'returns 200 for index' do
      get sites_path
      expect(response).to have_http_status(200)
    end

    it 'returns 200 for show' do
      get site_path(site)
      expect(response).to have_http_status(200)
      expect(response.body).to include(site.title)
    end

    it 'returns 200 for edit' do
      get edit_site_path(site)
      expect(response).to have_http_status(200)
    end

    it 'updates a site and redirects back' do
      get edit_site_path(site), headers: { 'HTTP_REFERER' => sites_path }

      patch site_path(site), params: {
        site: {
          title: 'Updated Site Title',
          address1: site.address1,
          address2: site.address2,
          city: site.city,
          state: site.state,
          zip_code: site.zip_code
        }
      }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(/\/sites#top|\/sites$/)
      expect(site.reload.title).to eq('Updated Site Title')
    end

    it 'renders edit with 422 for invalid update' do
      patch site_path(site), params: {
        site: {
          title: '',
          address1: '',
          city: '',
          state: '',
          zip_code: 'BADZIP'
        }
      }

      expect(response).to have_http_status(422)
    end
  end

  context 'with admin role' do
    let!(:admin_user) { FactoryBot.create(:user) }

    before do
      stub_admin_access(admin_user, unit)
      mock_login(admin_user)
    end

    it 'returns 200 for index' do
      get sites_path
      expect(response).to have_http_status(200)
    end
  end

  context 'with manager instructor role' do
    let!(:manager_user) { FactoryBot.create(:user) }
    let!(:manager) { FactoryBot.create(:manager, uniqname: manager_user.uniqname) }
    let!(:program) { FactoryBot.create(:program, unit: unit, instructor: manager) }

    before do
      stub_non_admin_access(manager_user)
      mock_login(manager_user)
    end

    it 'is not authorized for index' do
      get sites_path
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_manager_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is authorized for show' do
      get site_path(site)
      expect(response).to have_http_status(200)
    end

    it 'is authorized for update' do
      get edit_site_path(site), headers: { 'HTTP_REFERER' => sites_path }

      patch site_path(site), params: {
        site: {
          title: 'Manager Updated Site',
          address1: site.address1,
          address2: site.address2,
          city: site.city,
          state: site.state,
          zip_code: site.zip_code
        }
      }

      expect(response).to have_http_status(302)
      expect(site.reload.title).to eq('Manager Updated Site')
    end
  end

  context 'with manager non-instructor role' do
    let!(:manager_user) { FactoryBot.create(:user) }
    let!(:manager) { FactoryBot.create(:manager, uniqname: manager_user.uniqname) }

    before do
      stub_non_admin_access(manager_user)
      mock_login(manager_user)
    end

    it 'is not authorized for show' do
      get site_path(site)
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_manager_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end

  context 'with student role' do
    let!(:student_user) { FactoryBot.create(:user) }
    let!(:instructor) { FactoryBot.create(:manager) }
    let!(:program) { FactoryBot.create(:program, unit: unit, instructor: instructor) }
    let!(:student) { FactoryBot.create(:student, uniqname: student_user.uniqname, program: program) }

    before do
      stub_non_admin_access(student_user)
      mock_login(student_user)
    end

    it 'is not authorized for index' do
      get sites_path
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_student_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is not authorized for show' do
      get site_path(site)
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
      get sites_path
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is not authorized for show' do
      get site_path(site)
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end
end
