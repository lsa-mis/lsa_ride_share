require 'rails_helper'

RSpec.describe UnitPolicy, type: :policy do
  let(:user) { FactoryBot.create(:user) }
  let(:unit) { Unit.new }

  context 'with super_admin role' do
    subject { described_class.new({ user: user, role: "super_admin" }, unit) }

    it { is_expected.to forbid_actions(%i[is_admin is_student is_manager]) }
    it { is_expected.to permit_only_actions(%i[is_super_admin user_in_access_group index create new update edit destroy]) }
  end

  context 'with admin role' do
    subject { described_class.new({ user: user, role: "admin" }, unit) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_student is_manager index create new update edit destroy]) }
    it { is_expected.to permit_only_actions(%i[is_admin user_in_access_group]) }
  end

  context 'with manager role' do
    subject { described_class.new({ user: user, role: "manager" }, unit) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_admin is_student user_in_access_group index create new update edit destroy]) }
    it { is_expected.to permit_only_actions(%i[is_manager]) }
  end

  context 'with student role' do
    subject { described_class.new({ user: user, role: "student" }, unit) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_admin is_manager user_in_access_group index create new update edit destroy]) }
    it { is_expected.to permit_only_actions(%i[is_student]) }
  end

  context 'with no role' do
    subject { described_class.new({ user: user, role: "none" }, unit) }

    it { is_expected.to forbid_all_actions }
  end

end
