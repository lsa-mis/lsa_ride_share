class SystemReportPolicy < ApplicationPolicy

  def index?
    user_in_access_group?
  end

  def run_report?
    user_in_access_group?
  end

  def vehicle_reports_report?
    user_in_access_group?
  end

  def totals_programs_report?
    user_in_access_group?
  end

end
