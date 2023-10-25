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
#  recurring                :text
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
#  prev                     :bigint
#  next                     :bigint
#  until_date               :date
#
class Reservation < ApplicationRecord
  include ApplicationHelper
  belongs_to :program
  belongs_to :site
  belongs_to :car, optional: true
  belongs_to :driver, optional: true, class_name: 'Student', foreign_key: :driver_id
  belongs_to :driver_manager, optional: true, class_name: 'Manager', foreign_key: :driver_manager_id
  belongs_to :backup_driver, optional: true, class_name: 'Student', foreign_key: :backup_driver_id

  has_one :next_reservation, class_name: "Reservation", foreign_key: :next
  belongs_to :prev_reservation, class_name: "Reservation", foreign_key: :prev, optional: true


  has_many :reservation_passengers
  has_many :passengers, through: :reservation_passengers, source: :student
  has_one :vehicle_report, dependent: :destroy
  before_update :check_number_of_non_uofm_passengers
  before_create :check_recurring
  
  has_rich_text :note

  validate :check_number_of_people_on_trip, on: :update
  validate :driver_student_or_manager, on: :update
  validate :check_diff_time
  validate :approve_requires_car, on: :update

  scope :with_passengers, -> { Reservation.includes(:passengers) }
  scope :include_vehicle_reports, -> { Reservation.includes(:vehicle_report) }
  scope :current_term, -> { include_vehicle_reports.where(program_id: Program.current_term.ids)}
  scope :current_past, -> { current_term.where("(end_time < ?) OR (start_time < ? AND end_time > ?)",
    Date.today.end_of_day, Date.today.end_of_day, Date.today.beginning_of_day) }
  scope :with_no_vehicle_reports, -> { current_past.where(vehicle_report: {id: nil}) }
  scope :with_not_complete_vehicle_reports, -> { current_past.where(vehicle_report: {student_status: false}) }
  scope :no_or_not_complete_vehicle_reports, -> { Reservation.with_not_complete_vehicle_reports.or(Reservation.with_no_vehicle_reports) }
  scope :complete_vehicle_reports, -> { current_term.where(vehicle_report: {student_status: true}) }

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

   def check_number_of_non_uofm_passengers
    unless self.number_of_non_uofm_passengers.present?
      self.number_of_non_uofm_passengers = 0
    end
  end

  def driver_student_or_manager
    if self.driver_id.present? && self.driver_manager_id.present?
      self.driver_manager_id = nil
    end
  end

  def check_diff_time
    if ((self.end_time - self.start_time) / 1.minute).to_i < 46
      errors.add(:end_time, " is too close to Start Time")
    end
  end

  def approve_requires_car
    if self.approved
      errors.add(:base, " can't approve without a car") unless self.car_id.present?
    end
  end

  def dup
    super.tap do |new_reservation|
      new_reservation.start_time = nil
      new_reservation.end_time = nil
      new_reservation.prev = nil
      new_reservation.next = nil
    end
  end

  def check_recurring
    if self.recurring.present?
      if self.until_date.present?
        recurring[:until] = self.until_date.to_s
      end
    end
  end

  serialize :recurring, Hash

  def recurring=(value)
    if RecurringSelect.is_valid_rule?(value)
      v = RecurringSelect.dirty_hash_to_rule(value).to_hash
      super(v)
    else
      super(nil)
    end
  end

  def rule
    IceCube::Rule.from_hash recurring
  end

  def schedule(start)
    schedule = IceCube::Schedule.new(start)
    # start_time = params['schedule_starttime']
    schedule.add_recurrence_rule(rule)
    schedule
  end

  def calendar_reservations(start)
    if recurring.empty?
      [self]
    else
      start_date = start.beginning_of_month.beginning_of_week
      end_date = start.end_of_month.end_of_week
      schedule(start_time).occurrences(end_date).map do |date|
        Reservation.new(id: id, start_time: date)
      end
    end
  end

end
