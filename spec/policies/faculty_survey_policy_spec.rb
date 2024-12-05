require 'rails_helper'

RSpec.describe FacultySurveyPolicy, type: :policy do

  context 'with super_admin role' do
    let(:user) { FactoryBot.create(:user) }
    let(:faculty_survey) { FactoryBot.create(:faculty_survey) }
    subject { described_class.new({ user: user, role: "super_admin", unit_ids: [faculty_survey.unit_id] }, faculty_survey) }
    it { is_expected.to forbid_actions(%i[is_admin is_student is_manager surveys_index]) }
    it { is_expected.to permit_only_actions(%i[is_super_admin user_in_access_group index show create new update edit send_faculty_survey_email destroy]) }
  end

  context 'with admin role' do
    let(:user) { FactoryBot.create(:user) }
    let(:faculty_survey) { FactoryBot.create(:faculty_survey) }
    subject { described_class.new({ user: user, role: "admin", unit_ids: [faculty_survey.unit_id] }, faculty_survey) }
    it { is_expected.to forbid_actions(%i[is_super_admin is_student is_manager surveys_index]) }
    it { is_expected.to permit_only_actions(%i[is_admin user_in_access_group index show create new update edit send_faculty_survey_email destroy]) }
  end

  context 'with manager role' do
    let(:user) { FactoryBot.create(:user) }
    let(:manager) { FactoryBot.create(:manager, uniqname: user.uniqname) }
    let(:faculty_survey) { FactoryBot.create(:faculty_survey, uniqname: manager.uniqname) }
    subject { described_class.new({ user: manager, role: "manager", unit_ids: [faculty_survey.unit_id] }, [faculty_survey]) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_admin is_student user_in_access_group index create new update edit send_faculty_survey_email destroy]) }
    it { is_expected.to permit_only_actions(%i[is_manager surveys_index]) }
  end

  context 'with student role' do
    let(:user) { FactoryBot.create(:user) }
    let(:student) { FactoryBot.create(:student) }
    let(:faculty_survey) { FactoryBot.create(:faculty_survey, unit: Unit.first) }
    subject { described_class.new({ user: student, role: "student", unit_ids: [faculty_survey.unit_id] }, faculty_survey) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_admin is_manager user_in_access_group index surveys_index create new update edit send_faculty_survey_email destroy]) }
    it { is_expected.to permit_only_actions(%i[is_student]) }
  end

  context 'with no role' do
    let(:user) { FactoryBot.create(:user) }
    let(:faculty_survey) { FactoryBot.create(:faculty_survey) }
    subject { described_class.new({ user: user, role: "none" }, faculty_survey) }

    it { is_expected.to forbid_all_actions }
  end

end
