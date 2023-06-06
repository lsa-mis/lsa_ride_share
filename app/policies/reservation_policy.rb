# frozen_string_literal: true

class ReservationPolicy < ApplicationPolicy

  def index?
    user_in_access_group?
  end

  def show?
    user_in_access_group? || is_student?
  end

  def create?
    user_in_access_group? || is_student?
  end

  def new?
    create?
  end

  def update?
    user_in_access_group? || is_student?
  end

  def edit?
    update?
  end

  def get_available_cars?
    create?
  end

  def add_drivers?
    update?
  end

  def add_passengers?
    update?
  end

  def remove_passenger?
    update?
  end

end
