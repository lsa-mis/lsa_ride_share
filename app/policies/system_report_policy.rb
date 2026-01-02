class SystemReportPolicy < ApplicationPolicy

  def index?
    user_in_access_group?
  end

  def vehicle_reports_all_report?
    user_in_access_group?
  end

  def totals_programs_report?
    user_in_access_group?
  end

  def approved_drivers_report?
    user_in_access_group?
  end

  def reservations_for_student_report?
    user_in_access_group?
  end

  def import_reservations_report?
    user_in_access_group?
  end

end
