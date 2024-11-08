require 'rails_helper'

RSpec.describe WelcomePagePolicy, type: :policy do
  let(:user) { FactoryBot.create(:user) }
  let(:user_manager) { FactoryBot.create(:user) }
  let(:manager) { FactoryBot.create(:manager, uniqname: user_manager.uniqname) }
  let(:user_student) { FactoryBot.create(:user) }
  let(:student) { FactoryBot.create(:student, uniqname: user_student.uniqname, program: program) }

  context 'with super_admin role' do
    subject { described_class.new({ user: user, role: "super_admin" }, :welcome_page) }

    it { is_expected.to forbid_actions(%i[is_admin is_student is_manager add_student_phone edit_student_phone add_manager_phone edit_manager_phone]) }
    it { is_expected.to permit_only_actions(%i[is_super_admin user_in_access_group get_instructor_id]) }
  end

  context 'with admin role' do
    subject { described_class.new({ user: user, role: "admin" }, car) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_student is_manager]) }
    it { is_expected.to permit_only_actions(%i[is_admin user_in_access_group index show create new update edit get_parking_locations delete_file get_instructor_id]) }
  end

  context 'with manager role' do
    subject { described_class.new({ user: user, role: "manager" }, car) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_admin is_student index create new update edit get_parking_locations delete_file get_instructor_id]) }
    it { is_expected.to permit_only_actions(%i[is_manager show]) }
  end

  context 'with student role' do
    subject { described_class.new({ user: user, role: "student" }, car) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_admin is_manager index create new update edit get_parking_locations delete_file get_instructor_id]) }
    it { is_expected.to permit_only_actions(%i[is_student show]) }
  end

  context 'with no role' do
    subject { described_class.new({ user: user, role: "none" }, car) }

    it { is_expected.to forbid_all_actions }
  end

end
