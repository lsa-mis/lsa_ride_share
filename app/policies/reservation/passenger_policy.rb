class  Reservation::PassengerPolicy < ReservationPolicy

  def initialize(context, record)
    @user = context[:user]
    @params = context[:params]
    @role = context[:role]
    @unit_ids = context[:unit_ids]
    @record = Reservation.find(@params[:reservation_id])
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
    user_in_access_group? || is_in_reservation?
  end

end
