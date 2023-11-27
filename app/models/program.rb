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
#  mvr_link                            :string
#  canvas_link                         :string
#  canvas_course_id                    :integer
#  term_id                             :integer
#  add_managers                        :boolean          default(FALSE)
#  not_course                          :boolean          default(FALSE)
#  unit_id                             :bigint
#
class Program < ApplicationRecord
  belongs_to :instructor, class_name: 'Manager', foreign_key: :instructor_id
  has_many :managers_programs
  has_many :managers, through: :managers_programs
  has_many :programs_sites
  has_many :sites, through: :programs_sites
  has_many :students
  has_many :reservations
  belongs_to :unit
  belongs_to :term
  has_many :courses

  accepts_nested_attributes_for :instructor
  accepts_nested_attributes_for :courses

  validates_presence_of :title, :instructor_id, :unit_id
  validates :term_id, uniqueness: { scope: [:title], message: "already has this program" }


  scope :current_term, -> { where(term_id: Term.current) }
  scope :data, ->(term_id) { term_id.present? ? where(term_id: term_id) : current_term }

  def dup
    super.tap do |new_program|
      new_program.term_id = nil
      new_program.number_of_students = ""
      new_program.number_of_students_using_ride_share = ""
      new_program.updated_by = ""
    end
  end

  def additional_options
    options = ''
    if self.pictures_required_start 
      options += 'Users are required to add pictures at beginning of their trip<br>'
    end
    if self.pictures_required_end
      options += 'Users are required to add pictures at beginning of their trip<br>'
    end
    if self.non_uofm_passengers
      options += 'Reservation can include non U-M passengers<br>'
    end
    if self.add_managers
      options += 'Program have managers<br>'
    end
    options
  end

  def display_name
    if self.not_course
      name = "Not a course - #{self.term.name}"
    else
      name = ""
      self.courses.each do |course|
       name += course.display_name + "; "
      end
      name += "#{self.term.name}"
    end
    return name
  end

  def display_name_with_title
    if self.not_course
      "#{self.title} - not a course - #{self.term.name}"
    else
      "#{self.title} - #{self.display_name}"
    end
  end

  def title_term
    "#{self.title} - #{self.term.name}"
  end

  def display_name_with_title_and_unit
    if self.not_course
      "#{self.unit.name} - #{self.title} - not a course - #{self.term.name}"
    else
      "#{self.unit.name} - #{self.title} - #{self.display_name}"
    end
  end

  def all_managers
    self.managers.map(&:uniqname) << self.instructor.uniqname
  end

end
