# == Schema Information
#
# Table name: config_questions
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :config_question do
    question { Faker::Lorem.question}
    answer { "" }
    association :faculty_survey
  end
end
