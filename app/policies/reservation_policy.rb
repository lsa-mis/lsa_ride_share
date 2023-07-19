# frozen_string_literal: true

class ReservationPolicy < ApplicationPolicy

  def index?
    user_in_access_group?
  end

  def week_calendar?
    user_in_access_group?
  end

  def day_reservations?
    user_in_access_group?
  end

  def show?
    user_in_access_group? || is_reservation_student?
  end

  def create?
    user_in_access_group? || is_student?
  end

  def new?
    create?
  end

  def update?
    user_in_access_group? || is_reservation_driver?
  end

  def edit?
    update?
  end

  def get_available_cars?
    create?
  end

  def no_car_all_times?
    create?
  end

  def edit_change_day?
    create?
  end

  def add_drivers?
    user_in_access_group? || is_reserved_by?
  end

  def add_non_uofm_passengers?
    user_in_access_group? || is_reserved_by?
  end

  def finish_reservation?
    update?
  end

  def add_non_uofm_passengers?
    update?
  end

  def update_passengers?
    update?
  end

  def destroy?
    user_in_access_group? || is_reservation_driver?
  end

  def is_reservation_student?
    student = Student.find_by(program_id: @record.program, uniqname: @user.uniqname)
    @record.driver == student || @record.backup_driver == student || @record.passengers.include?(student)
  end

  def is_reservation_driver?
    student = Student.find_by(program_id: @record.program, uniqname: @user.uniqname)
    @record.driver == student || @record.backup_driver == student
  end

  def is_reserved_by?
    @record.reserved_by == user.id
  end

end
