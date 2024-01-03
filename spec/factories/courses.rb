# Table name: courses
#
#  subject                             :string           not null
#  catalog_number                      :string           not null
#  class_section                       :string           not null
#  program_id                          :integer
# 

FactoryBot.define do
  factory :course do
    subject { Faker::Educator.subject }
    catalog_number { Faker::Number.number(digits: 3) }
    class_section { Faker::Number.number.decimal_part(digits: 2) }
    association :program
  end
end
