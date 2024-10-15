# frozen_string_literal: true

class UnitPolicy < ApplicationPolicy

  def index?
    super_admin?
  end

  def create?
    super_admin?
  end

  def new?
    create?
  end

  def update?
    super_admin?
  end

  def edit?
    update?
  end

  def destroy?
    super_admin?
  end

end
