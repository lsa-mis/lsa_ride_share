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
  end

  factory :faculty_survey do
    uniqname { Faker::String.random(length: 3..8) }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    association :unit
    association :term

    factory :faculty_survey_with_config_question do
      config_questions { [association(:config_question)] }
    end
  end
end
