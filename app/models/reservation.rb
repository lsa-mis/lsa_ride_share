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
  before_destroy :car_reservation_cancel
  
  has_rich_text :note

  validate :check_number_of_people_on_trip, on: :update

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
    self.passengers.count + (self.driver.present? ? 1 : 0).to_i + (self.backup_driver.present? ? 1 : 0).to_i  
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
    if self.passengers.present?
      self.passengers.delete_all
    end
    ReservationMailer.car_reservation_cancel_admin(self, cancel_passengers, cancel_emails, self.reserved_by).deliver_now
    if self.driver_id.present?
      ReservationMailer.car_reservation_cancel_student(self, cancel_passengers, cancel_emails, self.reserved_by).deliver_now
    end
  end

end
