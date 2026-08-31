require 'rails_helper'

RSpec.describe UnitPreference, type: :request do
  let!(:unit) { FactoryBot.create(:unit) }

  context 'with super_admin role' do
    let!(:super_admin_user) { FactoryBot.create(:user) }

    before do
      stub_super_admin_access(super_admin_user, unit)
      mock_login(super_admin_user)
    end

    it 'returns 200 for index' do
      get unit_preferences_path

      expect(response).to have_http_status(200)
      expect(response.body).to include('Unit Preferences')
    end

    it 'returns 406 for new' do
      get new_unit_preference_path

      expect(response).to have_http_status(406)
    end

    it 'creates a unit preference for all units via turbo stream' do
      other_unit = FactoryBot.create(:unit)

      expect do
        post unit_preferences_path(format: :turbo_stream), params: {
          unit_preference: {
            name: 'reservation_time_begin',
            description: 'Reservation Start Time',
            pref_type: 'time'
          }
        }
      end.to change(UnitPreference, :count).by(2)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(UnitPreference.find_by(unit_id: unit.id, name: 'reservation_time_begin')).to be_present
      expect(UnitPreference.find_by(unit_id: other_unit.id, name: 'reservation_time_begin')).to be_present
    end

    it 'deletes all preferences with selected name' do
      up1 = FactoryBot.create(
        :unit_preference,
        unit: unit,
        name: 'delete_me_pref',
        description: 'Delete me',
        pref_type: :string,
        value: 'x'
      )
      unit2 = FactoryBot.create(:unit)
      up2 = FactoryBot.create(
        :unit_preference,
        unit: unit2,
        name: 'delete_me_pref',
        description: 'Delete me too',
        pref_type: :string,
        value: 'y'
      )

      expect do
        get delete_preference_path('delete_me_pref')
      end.to change(UnitPreference, :count).by(-2)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(unit_preferences_path)
      expect(flash[:notice]).to eq('Preference was deleted.')
    end
  end

  context 'with admin role' do
    let!(:admin_user) { FactoryBot.create(:user) }

    before do
      stub_admin_access(admin_user, unit)
      mock_login(admin_user)
    end

    it 'returns 200 for unit_prefs' do
      FactoryBot.create(
        :unit_preference,
        unit: unit,
        name: 'send_reminders',
        description: 'Send reminders',
        pref_type: :boolean,
        on_off: true,
        value: ''
      )

      get unit_prefs_path

      expect(response).to have_http_status(200)
      expect(response.body).to include('Unit Preferences')
    end

    it 'saves boolean/string/integer/time preferences and redirects with notice' do
      bool_pref = FactoryBot.create(
        :unit_preference,
        unit: unit,
        name: 'send_reminders',
        description: 'Send reminders',
        pref_type: :boolean,
        on_off: true,
        value: ''
      )
      str_pref = FactoryBot.create(
        :unit_preference,
        unit: unit,
        name: 'contact_phone',
        description: 'Contact phone',
        pref_type: :string,
        value: 'old'
      )
      int_pref = FactoryBot.create(
        :unit_preference,
        unit: unit,
        name: 'capacity_limit',
        description: 'Capacity limit',
        pref_type: :integer,
        value: '3'
      )
      time_pref = FactoryBot.create(
        :unit_preference,
        unit: unit,
        name: 'reservation_time_begin',
        description: 'Start time',
        pref_type: :time,
        value: '08:00'
      )

      post unit_prefs_path, params: {
        unit_prefs: {
          unit.id.to_s => {
            'contact_phone' => '734-111-2222',
            'capacity_limit' => 7,
            'reservation_time_begin' => '09:00'
          }
        }
      }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(unit_prefs_path)
      expect(flash[:notice]).to eq('Preferences are updated.')
      expect(bool_pref.reload.on_off).to eq(false)
      expect(str_pref.reload.value).to eq('734-111-2222')
      expect(int_pref.reload.value).to eq('7')
      expect(time_pref.reload.value).to eq('09:00')
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
      get unit_preferences_path

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_manager_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is not authorized for unit_prefs' do
      get unit_prefs_path

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

    it 'is not authorized for unit_prefs' do
      get unit_prefs_path

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
      get unit_preferences_path

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end
end
