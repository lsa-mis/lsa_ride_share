# == Schema Information
#
# Table name: students
#
#  id                          :bigint           not null, primary key
#  uniqname                    :string
#  last_name                   :string
#  first_name                  :string
#  mvr_expiration_date         :date
#  class_training_date         :date
#  canvas_course_complete_date :date
#  meeting_with_admin_date     :string
#  updated_by                  :integer
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#
class Student < ApplicationRecord
  has_and_belongs_to_many :programs
  has_rich_text :note
end
