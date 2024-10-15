# frozen_string_literal: true

class UnitPreferencePolicy < ApplicationPolicy

  def index?
    super_admin?
  end

  def unit_prefs?
    user_in_access_group?
  end

  def save_unit_prefs?
    user_in_access_group?
  end

  def create?
    super_admin?
  end

  def new?
    create?
  end

  def delete_preference?
    super_admin?
  end

end
