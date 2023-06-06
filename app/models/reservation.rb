# == Schema Information
#
# Table name: reservations
#
#  id                       :bigint           not null, primary key
#  status                   :string
#  program_id               :bigint           not null
#  site_id                  :bigint           not null
#  car_id                   :bigint
#  start_time               :datetime
#  end_time                 :datetime
#  recurring                :string
#  driver_id                :bigint
#  driver_phone             :string
#  backup_driver_id         :bigint
#  backup_driver_phone      :string
#  number_of_people_on_trip :integer
#  updated_by               :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  reserved_by              :integer
#
class Reservation < ApplicationRecord
  belongs_to :program
  belongs_to :site
  belongs_to :car, optional: true
  belongs_to :driver, optional: true, class_name: 'Student', foreign_key: :driver_id
  belongs_to :backup_driver, optional: true, class_name: 'Student', foreign_key: :backup_driver_id
  has_many :reservation_passengers
  has_many :passengers, through: :reservation_passengers, source: :student
  has_one :vehicle_report

  validate :check_driver_and_backup_driver
  
  has_rich_text :note

  scope :with_passengers, -> { Reservation.includes(:passengers) }

  def reservation_date
    start_d = start_time.present? ? start_time.strftime("%m/%d/%Y %I:%M%p") : ''
    end_d = end_time.present? ? end_time.strftime("%m/%d/%Y %I:%M%p") : ''
    "#{start_d} - #{end_d}"
  end

  def display_name
    if self.car_id.present?
      "car - #{self.car.car_number}"
    else
      "reservation ID - #{self.id}"
    end
  end

  def added_people
    self.passengers.count + (self.driver.present? ? 1 : 0).to_i + (self.backup_driver.present? ? 1 : 0).to_i  
  end

  def check_driver_and_backup_driver
    errors.add(:backup_driver, "can't be the same as driver") if self.driver_id == self.backup_driver_id
  end

end
