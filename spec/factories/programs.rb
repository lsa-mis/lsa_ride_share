# == Schema Information
#
# Table name: programs
#
#  id                                  :bigint           not null, primary key
#  title                               :string
#  number_of_students                  :integer
#  number_of_students_using_ride_share :integer
#  pictures_required_start             :boolean          default(FALSE)
#  pictures_required_end               :boolean          default(FALSE)
#  non_uofm_passengers                 :boolean          default(FALSE)
#  instructor_id                       :bigint           not null
#  updated_by                          :integer
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  mvr_link                            :string
#  canvas_link                         :string
#  canvas_course_id                    :integer
#  term_id                             :integer
#  add_managers                        :boolean          default(FALSE)
#  not_course                          :boolean          default(FALSE)
#  unit_id                             :bigint
#
FactoryBot.define do
  factory :program do
    title { "MyString" }
    number_of_students { 1 }
    number_of_students_using_ride_share { 1 }
    pictures_required_start { false }
    pictures_required_end { false }
    non_uofm_passengers { false }
    add_managers { false }
    not_course { false }
    updated_by { Faker::Types.rb_integer }
    mvr_link { "https://ltp.umich.edu/fleet/vehicle-use/" }
    canvas_link { "https://umich.instructure.com/courses/187918"}
    canvas_course_id { "187918" }
    association :instructor, factory: :manager
    association :unit
    association :term
  end
  # test
end
