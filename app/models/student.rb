# == Schema Information
#
# Table name: students
#
#  id                          :bigint           not null, primary key
#  uniqname                    :string
#  last_name                   :string
#  first_name                  :string
#  canvas_course_complete_date :date
#  meeting_with_admin_date     :date
#  updated_by                  :integer
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  mvr_status                  :string
#  program_id                  :bigint
#  registered                  :boolean          default(TRUE)
#
class Student < ApplicationRecord
  belongs_to :program
  has_many :reservation_passengers
  has_many :passengers, through: :reservation_passengers, source: :reservation
  has_many :notes, as: :noteable

  validates :uniqname, uniqueness: { scope: :program, message: "is already in the program list" }

  scope :registered, -> { where(registered: true) }

  def driver_past
    Reservation.where('driver_id = ? AND start_time <= ?', self, DateTime.now)
  end

  def driver_future
    Reservation.where('driver_id = ? AND start_time > ?', self, DateTime.now)
  end

  def backup_driver_past
    Reservation.where('backup_driver_id = ? AND start_time <= ?', self, DateTime.now)
  end

  def backup_driver_future
    Reservation.where('backup_driver_id = ? AND start_time > ?', self, DateTime.now)
  end

  def passenger_past
    Reservation.joins(:passengers).where('reservation_passengers.student_id = ? AND start_time <= ?', self, DateTime.now)
  end

  def passenger_future
    Reservation.joins(:passengers).where('reservation_passengers.student_id = ? AND start_time > ?', self, DateTime.now)
  end

  def reservations_past
    driver_past + backup_driver_past + passenger_past
  end

  def reservations_future
    driver_future + backup_driver_future + passenger_future
  end

  def reservations
    reservations_past + reservations_future
  end

  def display_name
    "#{self.first_name} #{self.last_name} - #{self.uniqname}" 
  end

  def name
    "#{self.first_name} #{self.last_name}" 
  end

  def can_reserve_car?
    self.mvr_status.present? && self.mvr_status.include?("Approved") && self.canvas_course_complete_date.present? && self.meeting_with_admin_date.present?
  end
  
  def self.eligible_drivers
    mvr_status.canvas_pass.meeting_with_admin
  end

  def self.mvr_status
    where("mvr_status LIKE ?", "Approved%")
  end

  def self.canvas_pass
    where.not(canvas_course_complete_date: nil) 
  end

  def self.meeting_with_admin
    where.not(meeting_with_admin_date: nil) 
  end

end
