require 'rails_helper'

RSpec.describe ConfigQuestionPolicy, type: :policy do

  context 'with super_admin role' do
    let(:user) { FactoryBot.create(:user) }
    let(:faculty_survey_with_config_questions) { FactoryBot.create(:faculty_survey_with_config_question) }
    subject { described_class.new({ user: user, role: "super_admin", unit_ids: [faculty_survey_with_config_questions.unit_id] }, faculty_survey_with_config_questions.config_questions) }
    it { is_expected.to forbid_actions(%i[is_admin is_student is_manager]) }
    it { is_expected.to permit_only_actions(%i[is_super_admin user_in_access_group index create new update edit destroy]) }
  end

  context 'with admin role' do
    let(:user) { FactoryBot.create(:user) }
    let(:faculty_survey_with_config_questions) { FactoryBot.create(:faculty_survey_with_config_question) }
    subject { described_class.new({ user: user, role: "admin", unit_ids: [faculty_survey_with_config_questions.unit_id] }, faculty_survey_with_config_questions.config_questions) }
    it { is_expected.to forbid_actions(%i[is_super_admin is_student is_manager]) }
    it { is_expected.to permit_only_actions(%i[is_admin user_in_access_group index create new update edit destroy]) }
  end

  context 'with manager role' do
    let(:user) { FactoryBot.create(:user) }
    let(:manager) { FactoryBot.create(:manager, uniqname: user.uniqname) }
    let(:faculty_survey_with_config_questions) { FactoryBot.create(:faculty_survey_with_config_question, uniqname: manager.uniqname) }
    subject { described_class.new({ user: manager, role: "manager", unit_ids: [faculty_survey_with_config_questions.unit_id] }, faculty_survey_with_config_questions.config_questions) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_admin is_student user_in_access_group create new update edit destroy]) }
    it { is_expected.to permit_only_actions(%i[is_manager index]) }
  end

  context 'with student role' do
    let(:user) { FactoryBot.create(:user) }
    let(:student) { FactoryBot.create(:student) }
    let(:faculty_survey_with_config_questions) { FactoryBot.create(:faculty_survey_with_config_question, unit: Unit.first) }
    subject { described_class.new({ user: student, role: "student", unit_ids: [faculty_survey_with_config_questions.unit_id] }, faculty_survey_with_config_questions.config_questions) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_admin is_manager user_in_access_group index create new update edit destroy]) }
    it { is_expected.to permit_only_actions(%i[is_student]) }
  end

  context 'with no role' do
    let(:user) { FactoryBot.create(:user) }
    let(:faculty_survey_with_config_questions) { FactoryBot.create(:faculty_survey_with_config_question) }
    subject { described_class.new({ user: user, role: "none" }, faculty_survey_with_config_questions.config_questions) }

    it { is_expected.to forbid_all_actions }
  end

end
