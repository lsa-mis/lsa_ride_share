# frozen_string_literal: true

class SitePolicy < ApplicationPolicy

  def index?
    user_in_access_group?
  end

  def show?
    return true if user_in_access_group? 
    return true if is_instructor?
    return false
  end

  def create?
    return true if user_in_access_group? 
    return true if is_instructor?
    return false
  end

  def new?
    create?
  end

  def update?
    return true if user_in_access_group? 
    return true if is_instructor?
    return false
  end

  def edit?
    update?
  end

  def is_instructor?
    manager = Manager.find_by(uniqname: @user.uniqname)
    Program.where(instructor_id: manager).present?
  end

end
