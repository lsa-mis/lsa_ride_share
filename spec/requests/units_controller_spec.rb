require 'rails_helper'

RSpec.describe Unit, type: :request do
  let!(:unit) { FactoryBot.create(:unit) }

  context 'with super_admin role' do
    let!(:super_admin_user) { FactoryBot.create(:user) }

    before do
      stub_super_admin_access(super_admin_user, unit)
      mock_login(super_admin_user)
    end

    it 'returns 200 for index' do
      get units_path
      expect(response).to have_http_status(200)
    end

    it 'returns 406 for new' do
      get new_unit_path
      expect(response).to have_http_status(406)
    end

    it 'creates a new unit and clones existing unit preference definitions' do
      template_unit = FactoryBot.create(:unit)
      FactoryBot.create(
        :unit_preference,
        unit: template_unit,
        name: 'send_reminders',
        description: 'Send reminders',
        pref_type: :boolean,
        on_off: true,
        value: ''
      )
      FactoryBot.create(
        :unit_preference,
        unit: template_unit,
        name: 'reservation_time_begin',
        description: 'Reservation start time',
        pref_type: :time,
        value: '08:00'
      )

      expect do
        post units_path(format: :turbo_stream), params: {
          unit: {
            name: 'New Unit For Test',
            ldap_group: 'newtestgroup'
          }
        }
      end.to change(Unit, :count).by(1)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')

      new_unit = Unit.find_by(name: 'New Unit For Test')
      expect(new_unit).to be_present
      expect(new_unit.unit_preferences.find_by(name: 'send_reminders')).to be_present
      expect(new_unit.unit_preferences.find_by(name: 'reservation_time_begin')).to be_present
      expect(new_unit.unit_preferences.find_by(name: 'send_reminders').on_off).to eq(false)
    end

    it 'updates a unit and redirects to index' do
      patch unit_path(unit), params: {
        unit: {
          name: 'Updated Unit Name',
          ldap_group: unit.ldap_group
        }
      }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(units_path)
      expect(unit.reload.name).to eq('Updated Unit Name')
    end

    it 'does not destroy a unit with programs' do
      FactoryBot.create(:program, unit: unit)

      expect do
        delete unit_path(unit, format: :turbo_stream)
      end.not_to change(Unit, :count)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(Unit.find_by(id: unit.id)).to be_present
    end

    it 'does not destroy a unit with cars' do
      FactoryBot.create(:car, unit: unit)

      expect do
        delete unit_path(unit, format: :turbo_stream)
      end.not_to change(Unit, :count)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(Unit.find_by(id: unit.id)).to be_present
    end

    it 'destroys a unit with no programs or cars' do
      removable_unit = FactoryBot.create(:unit, name: 'Removable Unit', ldap_group: 'remove_group')

      expect do
        delete unit_path(removable_unit, format: :turbo_stream)
      end.to change(Unit, :count).by(-1)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(Unit.find_by(id: removable_unit.id)).to be_nil
    end
  end

  context 'with admin role' do
    let!(:admin_user) { FactoryBot.create(:user) }

    before do
      stub_admin_access(admin_user, unit)
      mock_login(admin_user)
    end

    it 'is not authorized for index' do
      get units_path
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end

  context 'with manager role' do
    let!(:manager_user) { FactoryBot.create(:user) }
    let!(:manager) { FactoryBot.create(:manager, uniqname: manager_user.uniqname) }
    let!(:program) { FactoryBot.create(:program, unit: unit, instructor: manager) }

    before do
      stub_non_admin_access(manager_user)
      mock_login(manager_user)
    end

    it 'is not authorized for index' do
      get units_path
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_manager_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end

  context 'with student role' do
    let!(:instructor_user) { FactoryBot.create(:user) }
    let!(:instructor) { FactoryBot.create(:manager, uniqname: instructor_user.uniqname) }
    let!(:program) { FactoryBot.create(:program, unit: unit, instructor: instructor) }
    let!(:student_user) { FactoryBot.create(:user) }
    let!(:student) { FactoryBot.create(:student, uniqname: student_user.uniqname, program: program) }

    before do
      stub_non_admin_access(student_user)
      mock_login(student_user)
    end

    it 'is not authorized for index' do
      get units_path
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
      get units_path
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end
end
