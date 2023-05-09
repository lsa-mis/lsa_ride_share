# frozen_string_literal: true

class ProgramPolicy < ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user_in_access_group?
  end

  def show?
    user_in_access_group? || instructor?
  end

  def create?
    user_in_access_group?
  end

  def new?
    create?
  end

  def update?
    user_in_access_group? || instructor?
  end

  def edit?
    update?
  end

  def duplicate?
    update?
  end

  def program_data?
    update?
  end

  def destroy?
    false
  end

  def instructor?
    @record.instructor.uniqname == user.uniqname
  end

end
