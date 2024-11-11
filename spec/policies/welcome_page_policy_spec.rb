require 'rails_helper'

RSpec.describe WelcomePagePolicy, type: :policy do
  let(:user) { FactoryBot.create(:user) }

  context 'with super_admin role' do
    subject { described_class.new({ user: user, role: "super_admin" }, :welcome_page) }

    it { is_expected.to forbid_actions(%i[is_admin is_student is_manager add_student_phone edit_student_phone add_manager_phone edit_manager_phone manager student]) }
    it { is_expected.to permit_only_actions(%i[is_super_admin user_in_access_group]) }
  end

  context 'with admin role' do
    subject { described_class.new({ user: user, role: "admin" }, :welcome_page) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_student is_manager add_student_phone edit_student_phone add_manager_phone edit_manager_phone manager student]) }
    it { is_expected.to permit_only_actions(%i[is_admin user_in_access_group]) }
  end

  context 'with manager role' do
    subject { described_class.new({ user: user, role: "manager" }, :welcome_page) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_admin is_student user_in_access_group add_student_phone edit_student_phone student]) }
    it { is_expected.to permit_only_actions(%i[is_manager add_manager_phone edit_manager_phone manager]) }
  end

  context 'with student role' do
    subject { described_class.new({ user: user, role: "student" }, :welcome_page) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_admin is_manager user_in_access_group add_manager_phone edit_manager_phone manager]) }
    it { is_expected.to permit_only_actions(%i[is_student add_student_phone edit_student_phone student]) }
  end

  context 'with no role' do
    subject { described_class.new({ user: user, role: "none" }, :welcome_page) }

    it { is_expected.to forbid_all_actions }
  end

end
