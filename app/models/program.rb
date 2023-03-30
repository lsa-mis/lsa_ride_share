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
#  not_course                          :boolean          default(FALSE)
#  unit_id                             :bigint
#
class Program < ApplicationRecord
  belongs_to :instructor, class_name: 'ProgramManager', foreign_key: :instructor_id
  has_and_belongs_to_many :program_managers
  has_and_belongs_to_many :sites
  has_many :students
  has_and_belongs_to_many :cars
  has_many :reservations
  has_many :config_questions
  belongs_to :admin_access
  belongs_to :unit
  belongs_to :term

  accepts_nested_attributes_for :instructor

  validates_presence_of :title, :instructor_id, :admin_access_id
  validates_presence_of :subject, :catalog_number, :class_section, unless: -> { self.not_course }
  validates :term_id, uniqueness: { scope: [:subject, :catalog_number], message: "already has this program" }, unless: -> { self.not_course } 
  validates :term_id, uniqueness: { scope: [:title], message: "already has this program" }, if: -> { self.not_course }

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
    if self.pictures_required_start || self.pictures_required_end
      options = 'The program requires to upload pictures to the vehicle reports '
      if self.pictures_required_start
        options += '<br>at the start of the trip '
      end
      if self.pictures_required_start && self.pictures_required_end
        options += 'and '
      end
      if self.pictures_required_end
        options += '<br>at the end of the trip'
      end
    end
    if self.non_uofm_passengers
      options += '<br><br>Non UofM passangers are allowed'
    end
    options
  end

  def display_name
    if self.not_course
      "This program is not a course - #{self.term.name}"
    else
      "#{self.subject} #{self.catalog_number} - #{self.class_section} - #{self.term.name}"
    end
  end

end
