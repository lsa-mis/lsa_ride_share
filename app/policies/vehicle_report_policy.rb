# frozen_string_literal: true

class VehicleReportPolicy < ApplicationPolicy

  def index?
    user_in_access_group?
  end

  def show?
    user_in_access_group? || is_student?
  end

  def create?
    user_in_access_group? || is_student?
  end

  def new?
    create?
  end
  
  def update?
    user_in_access_group? || is_student?
  end

  def edit?
    update?
  end

  def destroy?
    false
  end
end
