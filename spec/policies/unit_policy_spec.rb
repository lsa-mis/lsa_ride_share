require 'rails_helper'

RSpec.describe UnitPolicy, type: :policy do
  let!(:user) { FactoryBot.create(:user) }
  let!(:unit) { Unit.new }

  context 'with super_admin role' do
    subject { described_class.new({ user: user, role: "super_admin" }, unit) }

    it { is_expected.to forbid_actions(%i[]) }
    it { is_expected.to permit_only_actions(%i[index create new update edit destroy]) }
  end

  context 'with admin role' do
    subject { described_class.new({ user: user, role: "admin" }, unit) }

    it { is_expected.to forbid_actions(%i[index create new update edit destroy]) }
    it { is_expected.to permit_only_actions(%i[]) }
  end

  context 'with manager role' do
    subject { described_class.new({ user: user, role: "manager" }, unit) }

    it { is_expected.to forbid_actions(%i[index create new update edit destroy]) }
    it { is_expected.to permit_only_actions(%i[]) }
  end

  context 'with student role' do
    subject { described_class.new({ user: user, role: "student" }, unit) }

    it { is_expected.to forbid_actions(%i[index create new update edit destroy]) }
    it { is_expected.to permit_only_actions(%i[]) }
  end

  context 'with no role' do
    subject { described_class.new({ user: user, role: "none" }, unit) }

    it { is_expected.to forbid_all_actions }
  end

end
