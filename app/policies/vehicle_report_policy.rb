# frozen_string_literal: true

class VehicleReportPolicy < ApplicationPolicy

  def index?
    user_in_access_group?
  end

  def show?
    return true if user_in_access_group?
    return true if is_vehicle_report_manager?
    return true if is_vehicle_report_student?
    return false
  end

  def create?
    reservation = reservation_for_create
    return false unless reservation.present?

    return true if user_in_access_group?
    return true if can_manager_create_report?(reservation)
    return true if can_student_create_report?(reservation)
    return false
  end

  def new?
    create?
  end
  
  def update?
    return true if user_in_access_group?
    return true if is_vehicle_report_manager?
    return true if is_vehicle_report_student?
    return false
  end

  def edit?
    update?
  end

  def upload_image?
    update?
  end

  def delete_image?
    update?
  end

  def destroy?
    update?
  end

  def upload_damage_images?
    update?
  end

  def upload_damage_form?
    user_in_access_group?
  end

  def delete_damage_form?
    user_in_access_group?
  end

  def download_vehicle_damage_form?
    user_in_access_group?
  end

  private

  def can_student_create_report?(reservation)
    student = Student.find_by(program_id: reservation.program, uniqname: @user.uniqname)
    return false unless student.present?
    if reservation.passengers.include?(student) || reservation.driver == student
      return true
    else
      return false
    end
  end

  def can_manager_create_report?(reservation)
    manager = Manager.find_by(uniqname: @user.uniqname)
    if reservation.driver_manager_id.present?
      return true if reservation.driver_manager == manager
    end
    managers = reservation.program.all_managers
    return true if reservation.passengers_managers.include?(manager)
    return false
  end

  def is_vehicle_report_student?
    report = VehicleReport.find(params[:id])
    can_student_create_report?(report.reservation)
  end

  def is_vehicle_report_manager?
    report = VehicleReport.find(params[:id])
    can_manager_create_report?(report.reservation)
  end

  def reservation_for_create
    reservation_id = if @record.respond_to?(:reservation_id)
      @record.reservation_id.presence
    else
      nil
    end
    reservation_id ||= params[:reservation_id]
    return nil unless reservation_id.present?

    Reservation.find_by(id: reservation_id)
  end

end
