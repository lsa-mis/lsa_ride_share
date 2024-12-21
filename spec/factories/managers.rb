# == Schema Information
#
# Table name: managers
#
#  id                          :bigint           not null, primary key
#  uniqname                    :string
#  first_name                  :string
#  last_name                   :string
#  updated_by                  :integer
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  program_id                  :bigint
#  mvr_status                  :string
#  canvas_course_complete_date :date
#  meeting_with_admin_date     :date
#  phone_number                :string
#

FactoryBot.define do
  factory :manager do
    uniqname { Faker::Alphanumeric.alpha(number: 8) }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    updated_by { Faker::Types.rb_integer }
    mvr_status { ['Approved', 'Expired', '', nil].sample }
    canvas_course_complete_date { Faker::Date.between(from: 2.months.ago, to: Date.today) }
    meeting_with_admin_date { Faker::Date.between(from: 2.months.ago, to: Date.today) }
  end
end
