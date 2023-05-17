# frozen_string_literal: true

class UnitPolicy < ApplicationPolicy

  def index?
    user_admin?
  end

  def create?
    user_admin?
  end

  def new?
    create?
  end

  def update?
    user_admin?
  end

  def edit?
    update?
  end

  def destroy?
    user_admin?
  end

end
