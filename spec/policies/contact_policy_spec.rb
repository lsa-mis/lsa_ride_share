require 'rails_helper'

RSpec.describe ContactPolicy, type: :policy do

  context 'with super_admin role' do
    let(:user) { FactoryBot.create(:user) }
    let(:site_with_contacts) { FactoryBot.create(:site_with_contact) }
    subject { described_class.new({ user: user, role: "super_admin", unit_ids: [site_with_contacts.unit_id] }, site_with_contacts.contacts) }
    it { is_expected.to forbid_actions(%i[is_admin is_student is_manager]) }
    it { is_expected.to permit_only_actions(%i[is_super_admin user_in_access_group index show create new update edit destroy]) }
  end

  context 'with admin role' do
    let(:user) { FactoryBot.create(:user) }
    let(:site_with_contacts) { FactoryBot.create(:site_with_contact) }
    subject { described_class.new({ user: user, role: "admin", unit_ids: [site_with_contacts.unit_id] }, site_with_contacts.contacts) }
    it { is_expected.to forbid_actions(%i[is_super_admin is_student is_manager]) }
    it { is_expected.to permit_only_actions(%i[is_admin user_in_access_group index show create new update edit destroy]) }
  end

  context 'with manager role' do
    let(:user) { FactoryBot.create(:user) }
    let(:manager) { FactoryBot.create(:manager, uniqname: user.uniqname) }
    let(:site_with_contacts) { FactoryBot.create(:site_with_contact) }
    subject { described_class.new({ user: manager, role: "manager", unit_ids: [site_with_contacts.unit_id] }, site_with_contacts.contacts) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_admin is_student user_in_access_group index show create new update edit destroy]) }
    it { is_expected.to permit_only_actions(%i[is_manager]) }
  end

  context 'with student role' do
    let(:user) { FactoryBot.create(:user) }
    let(:student) { FactoryBot.create(:student, uniqname: user.uniqname) }
    let(:site_with_contacts) { FactoryBot.create(:site_with_contact, unit: Unit.first) }
    subject { described_class.new({ user: student, role: "student", unit_ids: [site_with_contacts.unit_id] }, site_with_contacts.contacts) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_admin is_manager user_in_access_group index create new update edit destroy]) }
    it { is_expected.to permit_only_actions(%i[is_student]) }
  end

  context 'with no role' do
    let(:user) { FactoryBot.create(:user) }
    let(:site_with_contacts) { FactoryBot.create(:site_with_contact) }
    subject { described_class.new({ user: user, role: "none" }, site_with_contacts.contacts) }

    it { is_expected.to forbid_all_actions }
  end

end
