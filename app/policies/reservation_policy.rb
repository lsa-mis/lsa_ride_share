# frozen_string_literal: true

class ReservationPolicy < ApplicationPolicy

  def index?
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

  def get_available_cars?
    create?
  end

end
