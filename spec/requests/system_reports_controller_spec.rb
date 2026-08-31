require 'rails_helper'

RSpec.describe SystemReportsController, type: :request do
  let!(:unit) { FactoryBot.create(:unit) }
  let!(:term) do
    FactoryBot.create(
      :term,
      code: '4001',
      name: 'Report Term',
      classes_begin_date: Date.today - 10.days,
      classes_end_date: Date.today + 10.days
    )
  end
  let!(:instructor) { FactoryBot.create(:manager) }
  let!(:program) { FactoryBot.create(:program, unit: unit, term: term, instructor: instructor) }

  context 'with admin role' do
    let!(:admin_user) { FactoryBot.create(:user) }

    before do
      stub_admin_access(admin_user, unit)
      mock_login(admin_user)
    end

    it 'returns 200 for index' do
      get system_reports_path

      expect(response).to have_http_status(200)
      expect(response.body).to include('Reports')
      expect(response.body).to include('Vehicle Reports')
    end

    it 'returns 200 for vehicle_reports_all_report' do
      get vehicle_reports_all_report_system_reports_path

      expect(response).to have_http_status(200)
      expect(response.body).to include('Vehicle Reports Report')
    end

    it 'returns 200 for totals_programs_report' do
      get totals_programs_report_system_reports_path

      expect(response).to have_http_status(200)
      expect(response.body).to include('Totals by Programs Report')
    end

    it 'returns 200 for approved_drivers_report' do
      get approved_drivers_report_system_reports_path

      expect(response).to have_http_status(200)
      expect(response.body).to include('Approved Drivers Report')
    end

    it 'returns 200 for reservations_for_student_report' do
      get reservations_for_student_report_system_reports_path

      expect(response).to have_http_status(200)
      expect(response.body).to include('Reservations for Student Report')
    end

    it 'returns csv with no data when report is requested as csv without commit' do
      get vehicle_reports_all_report_system_reports_path(format: :csv)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/csv')
      expect(response.body).to include('No data found')
    end

    it 'renders totals report table with commit using stubbed result' do
      allow_any_instance_of(SystemReportsController).to receive(:get_result).and_return(
        [
          {
            'report_name' => 'totals_programs for Unit Term',
            'total' => 1,
            'header' => ['program', 'number_of_trips'],
            'rows' => [['Program A', '5']]
          }
        ]
      )

      get totals_programs_report_system_reports_path, params: {
        commit: 'Run Report',
        unit_id: unit.id,
        term_id: term.id,
        format: 'html'
      }

      expect(response).to have_http_status(200)
      expect(response.body).to include('Total 1')
      expect(response.body).to include('Program A')
    end

    it 'renders import reservations report with data for selected date range' do
      ImportReservationLog.create!(
        date: DateTime.current,
        user: 'report-user',
        unit_id: unit.id,
        status: 'success',
        note: 'import complete'
      )

      get import_reservations_report_system_reports_path, params: {
        commit: 'Run Report',
        unit_id: unit.id,
        from: (Date.today - 1.day).to_s,
        to: Date.today.to_s,
        format: 'html'
      }

      expect(response).to have_http_status(200)
      expect(response.body).to include('Import Reservations Report')
      expect(response.body).to include('success')
      expect(response.body).to include('report-user')
    end
  end

  context 'with manager role' do
    let!(:manager_user) { FactoryBot.create(:user) }
    let!(:manager) { FactoryBot.create(:manager, uniqname: manager_user.uniqname) }
    let!(:manager_program) { FactoryBot.create(:program, unit: unit, term: term, instructor: manager, title: 'Manager Program') }

    before do
      stub_non_admin_access(manager_user)
      mock_login(manager_user)
    end

    it 'is not authorized for index' do
      get system_reports_path

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

    it 'is not authorized for index' do
      get system_reports_path

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
      get system_reports_path

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end
end
