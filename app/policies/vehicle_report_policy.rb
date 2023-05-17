# frozen_string_literal: true

class VehicleReportPolicy < ApplicationPolicy

  def index?
    user_in_access_group?
  end

end
