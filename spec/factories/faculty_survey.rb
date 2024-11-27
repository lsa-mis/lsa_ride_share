# == Schema Information
#
# Table name: faculty_surveys
#
#  id         :bigint           not null, primary key
#  uniqname   :string
#  term_id    :bigint
#  unit_id    :bigint
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  program_id :integer
#  first_name :string
#  last_name  :string
#  title      :string
#

FactoryBot.define do
  factory :faculty_survey do
    uniqname { Faker::Alphanumeric.alpha(number: 8) }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    title { Faker::Lorem.words(number: 4) }
    association :unit
    association :term

    factory :faculty_survey_with_config_question do
      after(:create) do |faculty_survey|
        create(:config_question, faculty_survey: faculty_survey)
      end
    end
  end
end
