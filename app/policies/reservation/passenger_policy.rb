class  Reservation::PassengerPolicy < ReservationPolicy

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
