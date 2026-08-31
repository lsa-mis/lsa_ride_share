require 'rails_helper'

RSpec.describe Site, type: :request do
  let!(:unit) { FactoryBot.create(:unit) }
  let!(:term) { FactoryBot.create(:term) }
  let!(:instructor) { FactoryBot.create(:manager) }
  let!(:program) { FactoryBot.create(:program, unit: unit, term: term, instructor: instructor) }
  let!(:site) { FactoryBot.create(:site, unit: unit) }

  context 'with admin role' do
    let!(:admin_user) { FactoryBot.create(:user) }

    before do
      stub_admin_access(admin_user, unit)
      mock_login(admin_user)
    end

    it 'returns 200 for edit_program_sites' do
      get edit_program_sites_path(program)

      expect(response).to have_http_status(200)
      expect(response.body).to include('Edit Sites for')
    end

    it 'adds an existing site to program via turbo stream' do
      expect(program.sites).not_to include(site)

      post program_sites_path(program, format: :turbo_stream), params: { site_id: site.id }

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(program.reload.sites).to include(site)
    end

    it 'creates a new site and adds it to program via turbo stream' do
      expect do
        post program_sites_path(program, format: :turbo_stream), params: {
          site: {
            title: 'New Program Site',
            address1: '100 Main St',
            address2: '',
            city: 'Ann Arbor',
            state: 'MI',
            zip_code: '48104',
            unit_id: unit.id,
            updated_by: admin_user.id
          }
        }
      end.to change(Site, :count).by(1)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(program.reload.sites.pluck(:title)).to include('New Program Site')
    end

    it 'returns 200 for nested edit' do
      program.sites << site

      get edit_program_site_path(program, site)

      expect(response).to have_http_status(200)
    end

    it 'removes a site from program via turbo stream' do
      program.sites << site
      expect(program.sites).to include(site)

      delete remove_site_from_program_path(program, site, format: :turbo_stream)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(program.reload.sites).not_to include(site)
    end
  end

  context 'with manager as program instructor' do
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

    it 'is authorized for edit_program_sites' do
      get edit_program_sites_path(manager_program)

      expect(response).to have_http_status(200)
    end

    it 'can add an existing site to own program' do
      post program_sites_path(manager_program, format: :turbo_stream), params: { site_id: site.id }

      expect(response).to have_http_status(200)
      expect(manager_program.reload.sites).to include(site)
    end

    it 'can remove a site from own program' do
      manager_program.sites << site

      delete remove_site_from_program_path(manager_program, site, format: :turbo_stream)

      expect(response).to have_http_status(200)
      expect(manager_program.reload.sites).not_to include(site)
    end
  end

  context 'with manager not instructor for this program' do
    let!(:manager_user) { FactoryBot.create(:user) }
    let!(:manager) { FactoryBot.create(:manager, uniqname: manager_user.uniqname) }

    before do
      stub_non_admin_access(manager_user)
      mock_login(manager_user)
    end

    it 'is not authorized for edit_program_sites' do
      get edit_program_sites_path(program)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_manager_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is not authorized to add site' do
      post program_sites_path(program, format: :turbo_stream), params: { site_id: site.id }

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

    it 'is not authorized for edit_program_sites' do
      get edit_program_sites_path(program)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_student_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end
end
