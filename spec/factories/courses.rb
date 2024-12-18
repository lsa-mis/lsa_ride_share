# == Schema Information
#
# Table name: courses
#
#  id             :bigint           not null, primary key
#  subject        :string           not null
#  catalog_number :string           not null
#  class_section  :string           not null
#  program_id     :bigint
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

FactoryBot.define do
  factory :course do
    subject { Faker::Educator.subject }
    catalog_number { Faker::Number.number(digits: 3) }
    class_section { Faker::Number.decimal_part(digits: 3) }
    association :program
  end
end
