# frozen_string_literal: true

class ManagerPolicy < ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def create?
    user_in_access_group?
  end

  def new?
    create?
  end

  def edit_program_managers?
    create?
  end

  def remove_manager_from_program?
    user_in_access_group?
  end

end