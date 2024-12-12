# == Schema Information
#
# Table name: config_questions
#
#  id                :bigint           not null, primary key
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  faculty_survey_id :bigint
#
FactoryBot.define do
  factory :config_question do
    program { nil }
  end
end
