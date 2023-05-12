# frozen_string_literal: true

class SitePolicy < ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

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

  def edit_program_sites?
    update?
  end

  def remove_site_from_program?
    user_in_access_group? || is_instructor?
  end

  def is_instructor?
    manager = Manager.find_by(uniqname: @user.uniqname)
    Program.where(instructor_id: manager).present?
  end

end
