# == Schema Information
#
# Table name: managers
#
#  id         :bigint           not null, primary key
#  uniqname   :string
#  first_name :string
#  last_name  :string
#  updated_by :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  program_id :bigint
#  mvr_status                  :string
#  canvas_course_complete_date :date
#  meeting_with_admin_date     :date
#
class Manager < ApplicationRecord
  has_many :managers_programs
  has_many :programs, through: :managers_programs

  validates :uniqname, uniqueness: true

  def instructor
    Program.current_term.where(instructor: self)
  end

  def instructor_all_terms
    Program.where(instructor: self)
  end

  def manager
    Program.current_term.joins(:managers).where('managers_programs.manager_id = ?', self)
  end

  def manager_all_terms
    Program.joins(:managers).where('managers_programs.manager_id = ?', self)
  end

  def programs
    manager + instructor
  end

  def all_programs
    Program.where(instructor: self) + Program.joins(:managers).where('managers_programs.manager_id = ?', self)
  end

  def can_reserve_car?
    self.mvr_status.present? && self.mvr_status.include?("Approved") && self.canvas_course_complete_date.present? && self.meeting_with_admin_date.present?
  end

  def self.eligible_drivers
    mvr_status_pass.canvas_pass.meeting_with_admin_pass
  end

  def self.mvr_status_pass
    where("mvr_status LIKE ?", "Approved%")
  end

  def self.canvas_pass
    where.not(canvas_course_complete_date: nil) 
  end

  def self.meeting_with_admin_pass
    where.not(meeting_with_admin_date: nil) 
  end

  def reservations_current
    Reservation.no_or_not_complete_vehicle_reports.where('(reserved_by = ? OR driver_manager_id = ?)', User.find_by(uniqname: self.uniqname), self.id)
  end

  def reservations_past
    Reservation.complete_vehicle_reports.where('(reserved_by = ? OR driver_manager_id = ?)', User.find_by(uniqname: self.uniqname), self.id)
  end

  def reservations_future
    Reservation.current_term.where('(reserved_by = ? OR driver_manager_id = ?) AND start_time > ?', User.find_by(uniqname: self.uniqname), self.id, Date.today.end_of_day)
  end

  def display_name
    "#{self.first_name} #{self.last_name} - #{self.uniqname}" 
  end

  def name
    "#{self.first_name} #{self.last_name}"
  end

end
