# frozen_string_literal: true

class SitePolicy < ApplicationPolicy

  def index?
    user_in_access_group?
  end

  def show?
    user_in_access_group? || is_instructor?
  end

  def create?
    user_in_access_group? || is_instructor?
  end

  def new?
    create?
  end

  def update?
    user_in_access_group? || is_instructor?
  end

  def edit?
    update?
  end

  def is_instructor?
    manager = Manager.find_by(uniqname: @user.uniqname)
    Program.where(instructor_id: manager).present?
  end

end
