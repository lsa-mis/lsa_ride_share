# frozen_string_literal: true

class CarPolicy < ApplicationPolicy

  def index?
    user_in_access_group?
  end

  def show?
    return true if user_in_access_group? 
    return true if is_student?
    return false
  end

  def create?
    user_in_access_group?
  end

  def new?
    create?
  end

  def update?
    user_in_access_group?
  end

  def edit?
    update?
  end

  def get_parking_locations?
    create?
  end

  def delete_file?
    user_in_access_group?
  end

end
