# == Schema Information
#
# Table name: courses
#
#  subject                             :string           not null
#  catalog_number                      :string           not null
#  class_section                       :string           not null
#  program_id                          :integer
# 
class Course < ApplicationRecord
  belongs_to :program
  has_many :students

  before_save :upcase_subject

  validates_presence_of :subject, :catalog_number, :class_section, :program_id
  validate :course_uniqueness_in_program

  def display_name
    "#{self.subject} #{self.catalog_number} - #{self.class_section}"
  end

  def upcase_subject
    self.subject = subject.strip
    self.subject = subject.upcase
  end

  def course_uniqueness_in_program
    course = Course.where("UPPER(subject) = ? AND catalog_number = ? AND class_section = ? AND program_id = ?",
      self.subject.upcase, self.catalog_number, self.class_section, self.program_id).where.not(id: self.id)
    errors.add(:program_id, "already has this course") if course.present?
  end

end
