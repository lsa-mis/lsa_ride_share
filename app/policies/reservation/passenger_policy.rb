class  Reservation::PassengerPolicy < ReservationPolicy

  def initialize(context, record)
    @user = context[:user]
    @params = context[:params]
    @record = record
    @record = Reservation.find(@params[:reservation_id])
  end

  def add_passengers?
    user_in_access_group? || is_in_reservation?
  end

  def add_drivers_and_passengers?
    user_in_access_group? || is_in_reservation?
  end

  def add_passenger?
    user_in_access_group? || is_in_reservation?
  end

  def add_passenger_manager?
    user_in_access_group? || is_in_reservation?
  end

  def remove_passenger?
    user_in_access_group? || is_in_reservation?
  end

  def make_driver?
    user_in_access_group? || is_in_reservation?
  end

  def add_driver?
    user_in_access_group? || is_not_driver?
  end

  def is_in_reservation?
    # reservation = Reservation.find(params[:reservation_id])
    if is_student?
      student = Student.find_by(program_id: @record.program, uniqname: @user.uniqname)
      return @record.driver == student || @record.backup_driver == student || @record.passengers.include?(student)
    end
    if is_manager?
      manager = Manager.find_by(uniqname: @user.uniqname)
      return @record.driver_manager == manager || is_reserved_by? || @record.passengers_managers.include?(manager)
    end
    return false
  end

  def is_not_driver?
    # @record = @Record.find(params[:@record_id])
    if is_student?
      student = Student.find_by(program_id: @record.program, uniqname: @user.uniqname)
      return @record.passengers.include?(student)
    end
    if is_manager?
      manager = Manager.find_by(uniqname: @user.uniqname)
      return is_reserved_by? || @record.passengers_managers.include?(manager)
    end
    return false
  end

end
