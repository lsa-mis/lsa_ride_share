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
  has_many :reservation_passengers
  has_many :passengers, through: :reservation_passengers, source: :reservation
  has_rich_text :note

  def driver
    Reservation.where(driver: self)
  end

  def backup_driver
    Reservation.where(backup_driver: self)
  end

  def passenger
    Reservation.with_passengers.where(reservation_passengers: [self])
  end

  def all_reservations
    rwp = Reservation.with_passengers
    rwp.where(backup_driver: self).or(rwp.where(driver: self)).or(rwp.where(reservation_passengers: [self]))
  end
end
