# frozen_string_literal: true

class UnitPreferencePolicy < ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user_admin?
  end

  def unit_prefs?
    user_in_access_group?
  end

  def save_unit_prefs?
    user_in_access_group?
  end

  def create?
    user_admin?
  end

  def new?
    create?
  end

  def delete_preference?
    user_admin?
  end

end
