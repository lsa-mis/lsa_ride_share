# == Schema Information
#
# Table name: programs
#
#  id                                  :bigint           not null, primary key
#  active                              :boolean          default(TRUE)
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
#
class Program < ApplicationRecord
  belongs_to :instructor, class_name: 'ProgramManager', foreign_key: :instructor_id
  has_and_belongs_to_many :program_managers
  has_and_belongs_to_many :sites
  has_and_belongs_to_many :students
  has_and_belongs_to_many :cars
  has_many :reservations
  has_many :config_questions
  belongs_to :admin_access
  belongs_to :term

  accepts_nested_attributes_for :instructor

  validates_presence_of :title, :subject, :catalog_number, :class_section, :instructor_id, :admin_access_id
  
  scope :active, -> { where(active: true) }
  scope :archived, -> { where(active: false) }

  def dup
    super.tap do |new_program|

      new_program.term_id = nil
      new_program.number_of_students = ""
      new_program.number_of_students_using_ride_share = ""
      new_program.updated_by = ""
      new_program.active = true

    end
  end

  def display_name
    "#{self.subject.upcase} #{self.catalog_number.titleize} - #{self.class_section.titleize}"
  end

end
