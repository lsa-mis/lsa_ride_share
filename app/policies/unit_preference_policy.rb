# frozen_string_literal: true

class UnitPreferencePolicy < ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user_in_access_group?
  end

  def unit_prefs?
    user_in_access_group?
  end

  def save_unit_prefs?
    user_in_access_group?
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

  def delete_file?
    user_in_access_group?
  end

end
