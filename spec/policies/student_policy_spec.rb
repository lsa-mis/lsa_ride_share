require 'rails_helper'

RSpec.describe StudentPolicy, type: :policy do
  let!(:user) { FactoryBot.create(:user) }
  let!(:user_manager) { FactoryBot.create(:user) }
  let!(:manager) { FactoryBot.create(:manager, uniqname: user_manager.uniqname) }
  let!(:program_with_student) { FactoryBot.create(:program_with_student, instructor: manager) }

  context 'with super_admin role' do
    subject { described_class.new({ user: user, role: "super_admin" }, program_with_student.students) }

    it { is_expected.to forbid_actions(%i[]) }
    it { is_expected.to permit_only_actions(%i[index show create new update edit update_student_list add_students update_mvr_status update_student_mvr_status canvas_results student_canvas_result destroy get_programs_for_uniqname]) }
  end

  context 'with admin role' do
    subject { described_class.new({ user: user, role: "admin" }, program_with_student.students) }

    it { is_expected.to forbid_actions(%i[]) }
    it { is_expected.to permit_only_actions(%i[index show create new update edit update_student_list add_students update_mvr_status update_student_mvr_status canvas_results student_canvas_result destroy get_programs_for_uniqname]) }
  end

  context 'with manager role who is an instructor' do
    subject { described_class.new({ user: user_manager, params: {program_id: program_with_student.id }, role: "manager" }, program_with_student.students) }

    it { is_expected.to forbid_actions(%i[show update edit update_mvr_status update_student_mvr_status canvas_results student_canvas_result get_programs_for_uniqname]) }
    it { is_expected.to permit_only_actions(%i[index create new add_students update_student_list destroy]) }
  end

  # context 'with manager role who is a program manager' do
  #   let!(:user_program_manager) { FactoryBot.create(:user) }
  #   let!(:program_manager) { FactoryBot.create(:manager, uniqname: user_program_manager.uniqname) }
  #   let!(:program_with_student_and_manager) { FactoryBot.create(:program_with_student_and_manager) }
  #   subject { described_class.new({ user: program_manager, params: {program_id: program_with_student_and_manager.id }, role: "manager" }, program_with_student_and_manager.students) }

  #   it do
  #     binding.pry
  #     is_expected.to forbid_actions(%i[show update_student_list add_students create new update edit update_mvr_status update_student_mvr_status destroy]) 
  #   end
  #   it { is_expected.to permit_only_actions(%i[index]) }
  # end

  # context 'with student role' do
  #   let!(:user1) { FactoryBot.create(:user) }
  #   let!(:user_student) { FactoryBot.create(:student, uniqname: user1.uniqname, program: program_with_site) }
  #   subject { described_class.new({ user: user_student, role: "student" }, program_with_student.students) }

  #   it { is_expected.to forbid_actions(%i[index show create new update edit]) }
  #   it { is_expected.to permit_only_actions(%i[]) }
  # end

  context 'with no role' do
    subject { described_class.new({ user: user, params: {program_id: program_with_student.id }, role: "none" }, program_with_student.students) }

    it { is_expected.to forbid_all_actions }
  end

end
