# frozen_string_literal: true

class ManagerPolicy < ApplicationPolicy

  def index?
    user_in_access_group?
  end

  def create?
    user_in_access_group?
  end

  def new?
    create?
  end

  def edit?
    update?
  end

  def update?
    user_in_access_group?
  end

  def edit_program_managers?
    create?
  end

  def update_managers_mvr_status?
    create?
  end

  def remove_manager_from_program?
    user_in_access_group?
  end

end
