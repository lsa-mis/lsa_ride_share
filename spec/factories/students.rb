# == Schema Information
#
# Table name: students
#
#  id                          :bigint           not null, primary key
#  uniqname                    :string
#  last_name                   :string
#  first_name                  :string
#  class_training_date         :date
#  canvas_course_complete_date :date
#  meeting_with_admin_date     :string
#  updated_by                  :integer
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  mvr_status                  :string
#
FactoryBot.define do
  factory :student do
    uniqname { "MyString" }
    last_name { "MyString" }
    first_name { "MyString" }
    mvr_expiration_date { "2023-02-14" }
    class_training_date { "2023-02-14" }
    canvas_course_complete_date { "2023-02-14" }
    meeting_with_admin_date { "MyString" }
  end
end
