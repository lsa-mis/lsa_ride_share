require 'rails_helper'

RSpec.describe SystemReportPolicy, type: :policy do
  let(:user) { FactoryBot.create(:user) }

  context 'with super_admin role' do
    subject { described_class.new({ user: user, role: "super_admin" }, :system_report) }

    it { is_expected.to forbid_actions(%i[is_admin is_student is_manager]) }
    it { is_expected.to permit_only_actions(%i[is_super_admin user_in_access_group index run_report]) }
  end

  context 'with admin role' do
    subject { described_class.new({ user: user, role: "admin" }, :system_report) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_student is_manager]) }
    it { is_expected.to permit_only_actions(%i[is_admin user_in_access_group index run_report]) }
  end

  context 'with manager role' do
    subject { described_class.new({ user: user, role: "manager" }, :system_report) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_admin is_student user_in_access_group index run_report]) }
    it { is_expected.to permit_only_actions(%i[is_manager]) }
  end

  context 'with student role' do
    subject { described_class.new({ user: user, role: "student" }, :system_report) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_admin is_manager user_in_access_group index run_report]) }
    it { is_expected.to permit_only_actions(%i[is_student]) }
  end

  context 'with no role' do
    subject { described_class.new({ user: user, role: "none" }, :system_report) }

    it { is_expected.to forbid_all_actions }
  end

end
