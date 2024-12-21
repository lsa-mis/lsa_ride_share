# == Schema Information
#
# Table name: students
#
#  id                          :bigint           not null, primary key
#  uniqname                    :string
#  last_name                   :string
#  first_name                  :string
#  canvas_course_complete_date :date
#  updated_by                  :integer
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  mvr_status                  :string
#  program_id                  :bigint
#  meeting_with_admin_date     :date
#  registered                  :boolean          default(TRUE)
#  course_id                   :bigint
#  phone_number                :string
#
FactoryBot.define do
  factory :student do
    uniqname { Faker::String.random(length: 3..8) }
    last_name { Faker::Name.last_name }
    first_name { Faker::Name.first_name }
    mvr_status { ['Approved', 'Expired', '', nil].sample }
    canvas_course_complete_date { Faker::Date.between(from: 2.months.ago, to: Date.today) }
    meeting_with_admin_date { Faker::Date.between(from: 2.months.ago, to: Date.today) }
    association :program
  end
end
