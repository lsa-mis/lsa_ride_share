require 'rails_helper'

RSpec.describe UnitPreferencePolicy, type: :policy do
  let!(:user) { FactoryBot.create(:user) }
  let!(:unit_preference) { UnitPreference.new }

  context 'with super_admin role' do
    subject { described_class.new({ user: user, role: "super_admin" }, unit_preference) }

    it { is_expected.to forbid_actions(%i[]) }
    it { is_expected.to permit_only_actions(%i[index unit_prefs save_unit_prefs create new delete_preference]) }
  end

  context 'with admin role' do
    subject { described_class.new({ user: user, role: "admin" }, unit_preference) }

    it { is_expected.to forbid_actions(%i[index create delete_preference]) }
    it { is_expected.to permit_only_actions(%i[unit_prefs save_unit_prefs]) }
  end

  context 'with manager role' do
    let!(:manager) { FactoryBot.create(:manager, uniqname: user.uniqname) }
    subject { described_class.new({ user: user, role: "manager" }, unit_preference) }

    it { is_expected.to forbid_actions(%i[index unit_prefs save_unit_prefs create new delete_preference]) }
    it { is_expected.to permit_only_actions(%i[]) }
  end

  context 'with student role' do
    let!(:student) { FactoryBot.create(:student, uniqname: user.uniqname) }
    subject { described_class.new({ user: user, role: "student" }, unit_preference) }

    it { is_expected.to forbid_actions(%i[index unit_prefs save_unit_prefs create new delete_preference]) }
    it { is_expected.to permit_only_actions(%i[]) }
  end

  context 'with no role' do
    subject { described_class.new({ user: user, role: "none" }, unit_preference) }

    it { is_expected.to forbid_all_actions }
  end

end
