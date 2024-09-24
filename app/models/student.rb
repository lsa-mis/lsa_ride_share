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
#  phone_number                :string
#
class Student < ApplicationRecord
  belongs_to :program
  belongs_to :course, optional: true
  has_many :reservation_passengers
  has_many :passengers, through: :reservation_passengers, source: :reservation
  has_many :notes, as: :noteable

  validates :uniqname, uniqueness: { scope: :program, message: "is already in the program list" }

  scope :registered, -> { where(registered: true) }
  scope :added_manually, -> { where(registered: false) }


  def driver_current
    Reservation.no_or_not_complete_vehicle_reports.where(driver_id: self)
  end

  def backup_driver_current
    Reservation.no_or_not_complete_vehicle_reports.where(backup_driver_id: self)
  end

  def passenger_current
    Reservation.no_or_not_complete_vehicle_reports.joins(:passengers).where("reservation_passengers.student_id = ?", self)
  end

  def driver_past
    Reservation.complete_vehicle_reports.where(driver_id: self)
  end

  def backup_driver_past
    Reservation.complete_vehicle_reports.where(backup_driver_id: self)
  end

  def passenger_past
    Reservation.complete_vehicle_reports.joins(:passengers).where("reservation_passengers.student_id = ?", self)
  end

  def driver_future
    Reservation.where("driver_id = ? AND date_trunc('day', start_time) > ?", self, Date.today)
  end

  def backup_driver_future
    Reservation.where("backup_driver_id = ? AND date_trunc('day', start_time) > ?", self, Date.today)
  end

  def passenger_future
    Reservation.joins(:passengers).where("reservation_passengers.student_id = ? AND date_trunc('day', start_time) > ?", self, Date.today)
  end

  def reservations_current
    driver_current + backup_driver_current + passenger_current
  end

  def reservations_past
    driver_past + backup_driver_past + passenger_past
  end

  def reservations_future
    driver_future + backup_driver_future + passenger_future
  end

  def reservations
    reservations_current + reservations_past + reservations_future
  end

  def display_name
    "#{self.first_name} #{self.last_name} - #{self.uniqname}" 
  end

  def name
    "#{self.first_name} #{self.last_name}" 
  end

  def can_reserve_car?
    self.mvr_status.present? && self.mvr_status.include?("Approved until") && self.canvas_course_complete_date.present? && self.meeting_with_admin_date.present? && self.phone_number.present?
  end
  
  def self.eligible_drivers
    mvr_status_pass.canvas_pass.meeting_with_admin.has_phone
  end

  def self.mvr_status_pass
    where("mvr_status LIKE ?", "Approved until%")
  end

  def self.canvas_pass
    where.not(canvas_course_complete_date: nil) 
  end

  def self.meeting_with_admin
    where.not(meeting_with_admin_date: nil) 
  end

  def self.has_phone
    where.not(phone_number: nil)
  end

  def self.to_csv
    fields = %w{course registered uniqname last_name first_name phone_number mvr_status canvas_course_complete_date meeting_with_admin_date}
    header = %w{course registered uniqname last_name first_name phone_number mvr_status canvas_course_complete_date in_person_orientation_date}
    header.map! { |e| e.titleize.upcase }
    CSV.generate(headers: true) do |csv|
      csv << header
      all.each do |student|
        row = []
        fields.each do |key|
          if key == "course"
            if student.course.present?
              row << student.course.display_name
            else
              row << ""
            end
          elsif key == "registered"
            if student.attributes.values_at(key)[0]
              row << "yes"
            else
              row << "no"
            end
          else
            row << student.attributes.values_at(key)[0]
          end
        end
        csv << row
      end
    end
  end

end
