class SystemReportPolicy < ApplicationPolicy

  def index?
    user_in_access_group?
  end

  def run_report?
    user_in_access_group?
  end

end
