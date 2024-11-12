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
# has_many :config_questions, dependent: :destroy
# belongs_to :term
# belongs_to :unit

FactoryBot.define do
  factory :faculty_survey do
    uniqname { Faker::String.random(length: 3..8) }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    association :unit
    association :term
  end
end
