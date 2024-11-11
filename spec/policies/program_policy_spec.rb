require 'rails_helper'

RSpec.describe ProgramPolicy, type: :policy do
  let(:user) { FactoryBot.create(:user) }
  let(:user_manager) { FactoryBot.create(:user) }
  let(:manager) { FactoryBot.create(:manager, uniqname: user_manager.uniqname) }
  let(:program) { FactoryBot.create(:program, instructor: manager) }

  context 'with super_admin role' do
    subject { described_class.new({ user: user, role: "super_admin", params: {id: program.id} }, program) }

    it { is_expected.to forbid_actions(%i[is_admin is_student is_manager]) }
    it { is_expected.to permit_only_actions(%i[is_super_admin user_in_access_group index show create new update edit duplicate get_programs_list get_students_list get_sites_list]) }
  end

  context 'with admin role' do
    subject { described_class.new({ user: user, role: "admin", params: {id: program.id} }, program) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_student is_manager]) }
    it { is_expected.to permit_only_actions(%i[is_admin user_in_access_group index show create new update edit duplicate get_programs_list get_students_list get_sites_list]) }
  end

  context 'with manager role' do
    subject { described_class.new({ user: user_manager, role: "manager", params: {id: program.id} }, program) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_student is_admin create new]) }
    it { is_expected.to permit_only_actions(%i[is_manager is_instructor is_program_manager index show update edit duplicate]) }
  end

  context 'with student role' do
    subject { described_class.new({ user: user, role: "student", params: {id: program.id} }, program) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_admin is_manager index show create new update edit duplicate get_programs_list get_students_list get_sites_list]) }
    it { is_expected.to permit_only_actions(%i[is_student]) }
  end

  context 'with no role' do
    subject { described_class.new({ user: user, role: "none", params: {id: program.id} }, program) }

    it { is_expected.to forbid_all_actions }
  end

end
