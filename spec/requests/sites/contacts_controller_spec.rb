require 'rails_helper'

RSpec.describe Sites::ContactsController, type: :request do
  let!(:unit) { FactoryBot.create(:unit) }
  let!(:site) { FactoryBot.create(:site, unit: unit) }
  let!(:contact) { FactoryBot.create(:contact, site: site) }

  context 'with admin role' do
    let!(:admin_user) { FactoryBot.create(:user) }

    before do
      stub_admin_access(admin_user, unit)
      mock_login(admin_user)
    end

    it 'returns 200 for index' do
      get site_contacts_path(site)

      expect(response).to have_http_status(200)
      expect(response.body).to include('Update Contacts')
    end

    it 'returns 200 for show' do
      get site_contact_path(site, contact)

      expect(response).to have_http_status(200)
    end

    it 'creates a contact via turbo stream' do
      expect do
        post site_contacts_path(site, format: :turbo_stream), params: {
          contact: {
            title: 'Coordinator',
            first_name: 'Alex',
            last_name: 'Driver',
            phone_number: '734-111-2222',
            email: 'alex.driver@example.com'
          }
        }
      end.to change(Contact, :count).by(1)

      created = Contact.last
      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(created.site_id).to eq(site.id)
    end

    it 'does not create an invalid contact via turbo stream' do
      expect do
        post site_contacts_path(site, format: :turbo_stream), params: {
          contact: {
            title: '',
            first_name: '',
            last_name: '',
            phone_number: 'bad',
            email: 'bad-email'
          }
        }
      end.not_to change(Contact, :count)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
    end

    it 'updates a contact and redirects to site contacts index' do
      patch site_contact_path(site, contact), params: {
        contact: {
          title: 'Updated Title',
          first_name: contact.first_name,
          last_name: contact.last_name,
          phone_number: contact.phone_number,
          email: contact.email
        }
      }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(site_contacts_path(site))
      expect(contact.reload.title).to eq('Updated Title')
      expect(flash[:notice]).to eq('Contact was successfully updated.')
    end

    it 'destroys a contact via turbo stream' do
      expect do
        delete site_contact_path(site, contact, format: :turbo_stream)
      end.to change(Contact, :count).by(-1)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
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

    it 'is not authorized for index' do
      get site_contacts_path(site)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_manager_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is not authorized for create' do
      expect do
        post site_contacts_path(site), params: {
          contact: {
            title: 'Coordinator',
            first_name: 'Alex',
            last_name: 'Driver',
            phone_number: '734-111-2222',
            email: 'alex.driver@example.com'
          }
        }
      end.not_to change(Contact, :count)

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

    it 'is not authorized for index' do
      get site_contacts_path(site)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_student_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is not authorized for update' do
      patch site_contact_path(site, contact), params: {
        contact: {
          title: 'Student Updated'
        }
      }

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
      get site_contacts_path(site)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is not authorized for destroy' do
      expect do
        delete site_contact_path(site, contact)
      end.not_to change(Contact, :count)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end
end
