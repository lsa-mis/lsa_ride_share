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
#  approved                 :boolean          default false
#  non_uofm_passengers      :string
#  number_of_non_uofm_passengers :integer
#  driver_manager_id        :bigint
#
class Reservation < ApplicationRecord
  belongs_to :program
  belongs_to :site
  belongs_to :car, optional: true
  belongs_to :driver, optional: true, class_name: 'Student', foreign_key: :driver_id
  belongs_to :driver_manager, optional: true, class_name: 'Manager', foreign_key: :driver_manager_id
  belongs_to :backup_driver, optional: true, class_name: 'Student', foreign_key: :backup_driver_id
  has_many :reservation_passengers
  has_many :passengers, through: :reservation_passengers, source: :student
  has_one :vehicle_report, dependent: :destroy
  before_destroy :car_reservation_cancel
  before_update :check_number_of_non_uofm_passengers
  
  has_rich_text :note

  validate :check_number_of_people_on_trip, on: :update
  validate :driver_student_or_manager, on: :update
  validate :check_drivers, on: :update

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
      "No Car"
    end
  end

  def added_people
    number = self.passengers.count + (self.driver.present? ? 1 : 0).to_i + (self.backup_driver.present? ? 1 : 0).to_i + + (self.driver_manager.present? ? 1 : 0).to_i
    if self.program.non_uofm_passengers
      number += self.number_of_non_uofm_passengers
    end
    return number
  end

  def check_number_of_people_on_trip
    if self.number_of_people_on_trip_changed?
      if self.number_of_people_on_trip_change[0] > self.number_of_people_on_trip_change[1] && self.number_of_people_on_trip_change[1] < self.added_people
        errors.add(:number_of_people_on_trip, ": remove passengers before updating the number")
      end
    end
  end

  def car_reservation_cancel
    students = self.passengers
    cancel_passengers = []
    cancel_emails = []
    if students.present?
      students.each do |s|
        cancel_passengers << s.name
        cancel_emails << s.uniqname + "@umich.edu"
      end
    else
      cancel_passengers = ["No passengers"]
    end
    if self.program.non_uofm_passengers && self.non_uofm_passengers.present?
      cancel_passengers << "Non UofM Passengers: " + self.non_uofm_passengers
    end
    if self.passengers.present?
      self.passengers.delete_all
    end
    ReservationMailer.car_reservation_cancel_admin(self, cancel_passengers, cancel_emails, self.reserved_by).deliver_now
    if self.driver_id.present? || self.driver_manager_id.present? 
      ReservationMailer.car_reservation_cancel_driver(self, cancel_passengers, cancel_emails, self.reserved_by).deliver_now
    end
  end

  def check_number_of_non_uofm_passengers
    unless self.number_of_non_uofm_passengers.present?
      self.number_of_non_uofm_passengers = 0
    end
  end

  def driver_student_or_manager
    if [driver_id, driver_manager_id].compact.count != 1
      errors.add(:base, "Only one driver should be added: a student or a manager")
    end
  end

  def check_drivers
    if self.passengers.include?(self.driver)
      errors.add(:base, "remove this driver from the passenger list first.")
    end
    if self.passengers.include?(self.backup_driver)
      errors.add(:base, "remove this backup driver from the passengers list first.")
    end
  end

end
