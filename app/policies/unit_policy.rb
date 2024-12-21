# frozen_string_literal: true

class UnitPolicy < ApplicationPolicy

  def index?
    is_super_admin?
  end

  def create?
    is_super_admin?
  end

  def new?
    create?
  end

  def update?
    is_super_admin?
  end

  def edit?
    update?
  end

  def destroy?
    is_super_admin?
  end

end
