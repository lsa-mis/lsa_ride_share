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
#  meeting_with_admin_date     :date
#  updated_by                  :integer
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  mvr_status                  :string
#  program_id                  :bigint
#
class Student < ApplicationRecord
  belongs_to :program
  has_many :reservation_passengers
  has_many :passengers, through: :reservation_passengers, source: :reservation
  has_many :notes, as: :noteable

  validates :uniqname, uniqueness: { scope: :program, message: "is already in the program list" }

  def driver
    Reservation.where(driver: self)
  end

  def backup_driver
    Reservation.where(backup_driver: self)
  end

  def passenger
    Reservation.joins(:passengers).where('reservation_passengers.student_id = ?', self)
  end

  def reservations
    driver + backup_driver + passenger
  end

  def display_name
    "#{self.first_name} #{self.last_name} - #{self.uniqname}" 
  end

  def name
    "#{self.first_name} #{self.last_name}" 
  end

  def can_reserve_car?
    self.mvr_status.present? && self.mvr_status.include?("Approved") && self.canvas_course_complete_date.present? && self.meeting_with_admin_date.present? && self.class_training_date.present?
  end
  
  def self.eligible_drivers
    mvr_status.canvas_pass.class_training.meeting_with_admin
  end

  def self.mvr_status
    where("mvr_status LIKE ?", "Approved%")
  end

  def self.canvas_pass
    where.not(canvas_course_complete_date: nil) 
  end

  def self.class_training
    where.not(class_training_date: nil) 
  end

  def self.meeting_with_admin
    where.not(meeting_with_admin_date: nil) 
  end

end
