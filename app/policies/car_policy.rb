# frozen_string_literal: true

class CarPolicy < ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user_in_access_group?
    # true
  end

  def show?
    user_in_access_group?
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

  def destroy?
    false
  end

end
