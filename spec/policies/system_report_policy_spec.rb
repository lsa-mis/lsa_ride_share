require 'rails_helper'

RSpec.describe SystemReportPolicy, type: :policy do
  let!(:user) { FactoryBot.create(:user) }

  context 'with super_admin role' do
    subject { described_class.new({ user: user, role: "super_admin" }, :system_report) }

    it { is_expected.to forbid_actions(%i[]) }
    it { is_expected.to permit_only_actions(%i[index approved_drivers_report import_reservations_report reservations_for_student_report totals_programs_report vehicle_reports_all_report]) }
  end

  context 'with admin role' do
    subject { described_class.new({ user: user, role: "admin" }, :system_report) }

    it { is_expected.to forbid_actions(%i[]) }
    it { is_expected.to permit_only_actions(%i[index approved_drivers_report import_reservations_report reservations_for_student_report totals_programs_report vehicle_reports_all_report]) }
  end

  context 'with manager role' do
    subject { described_class.new({ user: user, role: "manager" }, :system_report) }

    it { is_expected.to forbid_actions(%i[index approved_drivers_report import_reservations_report reservations_for_student_report totals_programs_report vehicle_reports_all_report]) }
    it { is_expected.to permit_only_actions(%i[]) }
  end

  context 'with student role' do
    subject { described_class.new({ user: user, role: "student" }, :system_report) }

    it { is_expected.to forbid_actions(%i[index approved_drivers_report import_reservations_report reservations_for_student_report totals_programs_report vehicle_reports_all_report]) }
    it { is_expected.to permit_only_actions(%i[]) }
  end

  context 'with no role' do
    subject { described_class.new({ user: user, role: "none" }, :system_report) }

    it { is_expected.to forbid_all_actions }
  end

end
