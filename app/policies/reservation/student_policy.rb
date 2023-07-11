class  Reservation::StudentPolicy < ApplicationPolicy

  def add_passengers?
    user_in_access_group? || is_reservation_driver?
  end

  def add_passenger?
    user_in_access_group? || is_reservation_driver?
  end

  def remove_passenger?
    user_in_access_group? || is_reservation_driver?
  end

  def is_reservation_driver?
    student = Student.find_by(program_id: @record.program, uniqname: @user.uniqname)
    @record.driver == student
  end
  
  end
