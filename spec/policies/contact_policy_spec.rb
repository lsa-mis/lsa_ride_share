require 'rails_helper'

RSpec.describe ContactPolicy, type: :policy do
  let!(:user) { FactoryBot.create(:user) }
  let!(:site_with_contacts) { FactoryBot.create(:site_with_contact) }

  context 'with super_admin role' do
    subject { described_class.new({ user: user, role: "super_admin", unit_ids: [site_with_contacts.unit_id] }, site_with_contacts.contacts) }
    
    it { is_expected.to forbid_actions(%i[]) }
    it { is_expected.to permit_only_actions(%i[index show create new update edit destroy]) }
  end

  context 'with admin role' do
    subject { described_class.new({ user: user, role: "admin", unit_ids: [site_with_contacts.unit_id] }, site_with_contacts.contacts) }
    
    it { is_expected.to forbid_actions(%i[]) }
    it { is_expected.to permit_only_actions(%i[index show create new update edit destroy]) }
  end

  context 'with manager role' do
    let!(:manager) { FactoryBot.create(:manager, uniqname: user.uniqname) }
    subject { described_class.new({ user: manager, role: "manager", unit_ids: [site_with_contacts.unit_id] }, site_with_contacts.contacts) }
 
    it { is_expected.to forbid_actions(%i[index show create new update edit destroy]) }
    it { is_expected.to permit_only_actions(%i[]) }
  end

  context 'with student role' do
    let!(:student) { FactoryBot.create(:student, uniqname: user.uniqname) }
    let!(:site_with_contacts) { FactoryBot.create(:site_with_contact, unit: student.program.unit) }
    subject { described_class.new({ user: student, role: "student", unit_ids: [site_with_contacts.unit_id] }, site_with_contacts.contacts) }

    it { is_expected.to forbid_actions(%i[index create new update edit destroy]) }
    it { is_expected.to permit_only_actions(%i[]) }
  end

  context 'with no role' do
    subject { described_class.new({ user: user, role: "none" }, site_with_contacts.contacts) }
    
    it { is_expected.to forbid_all_actions }
  end

end
