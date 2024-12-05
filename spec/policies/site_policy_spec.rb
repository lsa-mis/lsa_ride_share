require 'rails_helper'

RSpec.describe SitePolicy, type: :policy do
  let(:user) { FactoryBot.create(:user) }
  let(:user_manager) { FactoryBot.create(:user) }
  let(:manager) { FactoryBot.create(:manager, uniqname: user_manager.uniqname) }
  let(:program_with_site) { FactoryBot.create(:program, instructor: manager) }

  context 'with super_admin role' do
    subject { described_class.new({ user: user, role: "super_admin" }, program_with_site.sites) }

    it { is_expected.to forbid_actions(%i[is_admin is_student is_manager is_instructor]) }
    it { is_expected.to permit_only_actions(%i[is_super_admin user_in_access_group index show create new update edit]) }
  end

  context 'with admin role' do
    subject { described_class.new({ user: user, role: "admin" }, program_with_site.sites) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_student is_manager is_instructor]) }
    it { is_expected.to permit_only_actions(%i[is_admin user_in_access_group index show create new update edit]) }
  end

  context 'with manager role' do
    subject { described_class.new({ user: user_manager, role: "manager" }, program_with_site.sites) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_admin is_student user_in_access_group index]) }
    it { is_expected.to permit_only_actions(%i[is_manager is_instructor show create new update edit]) }
  end

  context 'with student role' do
    let(:user1) { FactoryBot.create(:user) }
    let(:user_student) { FactoryBot.create(:student, uniqname: user1.uniqname, program: program_with_site) }
    subject { described_class.new({ user: user_student, role: "student" }, program_with_site.sites) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_admin is_manager is_instructor user_in_access_group index show create new update edit]) }
    it { is_expected.to permit_only_actions(%i[is_student]) }
  end

  context 'with no role' do
    subject { described_class.new({ user: user, role: "none" }, program_with_site.sites) }

    it { is_expected.to forbid_all_actions }
  end

end
