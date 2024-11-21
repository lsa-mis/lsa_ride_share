require 'rails_helper'

RSpec.describe ConfigQuestionPolicy, type: :policy do
  let(:user) { FactoryBot.create(:user) }
  let(:faculty_survey) { FactoryBot.create(:faculty_survey) }
  let(:faculty_survey_with_config_question[tgfdcx]) { FactoryBot.create(:faculty_survey_with_config_questions) }
  # create(:faculty_survey_with_config_questions).config_questions.length # 1
  # build(:faculty_survey_with_config_questions).config_questions.length # 1
  # build_stubbed(:faculty_survey_with_config_questions).config_questions.length
  # config_questions = faculty_survey.config_questions

  context 'with super_admin role' do
    subject { described_class.new({ user: user, role: "super_admin" }, faculty_survey.config_questions) }

    it { is_expected.to forbid_actions(%i[is_admin is_student is_manager]) }
    it { is_expected.to permit_only_actions(%i[is_super_admin user_in_access_group index create new update edit destroy]) }
  end

  context 'with admin role' do
    subject { described_class.new({ user: user, role: "admin" }, car) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_student is_manager]) }
    it { is_expected.to permit_only_actions(%i[is_admin user_in_access_group index show create new update edit get_parking_locations delete_file]) }
  end

  context 'with manager role' do
    subject { described_class.new({ user: user, role: "manager" }, car) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_admin is_student index create new update edit get_parking_locations delete_file]) }
    it { is_expected.to permit_only_actions(%i[is_manager show]) }
  end

  context 'with student role' do
    subject { described_class.new({ user: user, role: "student" }, car) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_admin is_manager index create new update edit get_parking_locations delete_file]) }
    it { is_expected.to permit_only_actions(%i[is_student show]) }
  end

  context 'with no role' do
    subject { described_class.new({ user: user, role: "none" }, car) }

    it { is_expected.to forbid_all_actions }
  end

end
