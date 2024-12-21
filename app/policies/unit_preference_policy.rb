# frozen_string_literal: true

class UnitPreferencePolicy < ApplicationPolicy

  def index?
    is_super_admin?
  end

  def unit_prefs?
    user_in_access_group?
  end

  def save_unit_prefs?
    user_in_access_group?
  end

  def create?
    is_super_admin?
  end

  def new?
    create?
  end

  def delete_preference?
    is_super_admin?
  end

end
