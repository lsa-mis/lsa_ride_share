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
    uniqname { "MyString" }
    term_id { 1 }
  end
end
