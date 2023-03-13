# == Schema Information
#
# Table name: programs
#
#  id                                  :bigint           not null, primary key
#  title                               :string
#  subject                             :string           not null
#  catalog_number                      :string           not null
#  class_section                       :string           not null
#  number_of_students                  :integer
#  number_of_students_using_ride_share :integer
#  pictures_required_start             :boolean          default(FALSE)
#  pictures_required_end               :boolean          default(FALSE)
#  non_uofm_passengers                 :boolean          default(FALSE)
#  instructor_id                       :bigint           not null
#  updated_by                          :integer
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  admin_access_id                     :bigint
#  mvr_link                            :string
#  canvas_link                         :string
#  canvas_course_id                    :integer
#  term_id                             :integer
#  add_managers                        :boolean          default(FALSE)
#
FactoryBot.define do
  factory :program do
    active { false }
    title { "MyString" }
    term_start { "2023-02-14" }
    term_end { "2023-02-14" }
    term_code { "MyString" }
    subject { "MyString" }
    catalog_number { "MyString" }
    class_section { "MyString" }
    number_of_students { 1 }
    number_of_students_using_ride_share { 1 }
    pictures_required_start { false }
    pictures_required_end { false }
    non_uofm_passengers { false }
  end
end
