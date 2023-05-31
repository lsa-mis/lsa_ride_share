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

end
