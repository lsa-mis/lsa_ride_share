# == Schema Information
#
# Table name: programs
#
#  id                                  :bigint           not null, primary key
#  active                              :boolean          default(TRUE)
#  title                               :string
#  term_start                          :date             not null
#  term_end                            :date             not null
#  term_code                           :string           not null
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
#
class Program < ApplicationRecord
  belongs_to :instructor, class_name: 'ProgramManager', foreign_key: :instructor_id
  has_many :program_managers
  has_and_belongs_to_many :sites
  has_and_belongs_to_many :students
end
