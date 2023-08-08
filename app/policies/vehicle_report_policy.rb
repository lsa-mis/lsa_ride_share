# frozen_string_literal: true

class VehicleReportPolicy < ApplicationPolicy

  def index?
    user_in_access_group?
  end

  def show?
    user_in_access_group? || is_vehicle_report_student?
  end

  def create?
    user_in_access_group? || can_student_save_report?
  end

  def new?
    user_in_access_group? || can_student_create_report?
  end
  
  def update?
    user_in_access_group? || is_vehicle_report_student?
  end

  def edit?
    update?
  end

  def destroy?
    update?
  end

  def can_student_create_report?
    reservation = Reservation.find(params[:reservation_id])
    student = Student.find_by(program_id: reservation.program, uniqname: @user.uniqname)
    return false unless student.present?
    if reservation.passengers.include?(student) || reservation.driver == student || reservation.backup_driver == student
      return true
    else
      return false
    end
  end

  def can_student_save_report?
    program = Reservation.find(params[:vehicle_report][:reservation_id]).program
    Student.find_by(program_id: program, uniqname: @user.uniqname).present?
  end

  def is_vehicle_report_student?
    report = VehicleReport.find(params[:id])
    reservation = report.reservation
    student = Student.find_by(program_id: reservation.program, uniqname: @user.uniqname)
    if reservation.passengers.include?(student) || reservation.driver == student || reservation.backup_driver == student
      return true
    else
      return false
    end
  end


end
