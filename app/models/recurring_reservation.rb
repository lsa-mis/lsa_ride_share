class RecurringReservation
  include ActionView::Helpers::SanitizeHelper
  include ApplicationHelper

  def initialize(reservation)
    @reservation = reservation
  end

  def reservation
    @reservation
  end

  def first_reservation
    if @reservation.prev.present?
      @reservation = Reservation.find(@reservation.prev)
      first_reservation
    else
      return @reservation
    end
  end

  def last_reservation
    if @reservation.next.present?
      @reservation = Reservation.find(@reservation.next)
      last_reservation
    else
      return @reservation
    end
  end

  def prev_reservation
    return false unless @reservation.prev.present?
    Reservation.find(@reservation.prev)
  end

  def next_reservation
    return false unless @reservation.next.present?
    Reservation.find(@reservation.next)
  end

  def start_on
    show_date(first_reservation.start_time)
  end

  def end_on
    show_date(last_reservation.end_time)
  end

  def create_all
    conflict_days_message = ""
    unless @reservation.recurring.empty?
      start_hour = @reservation.start_time.strftime("%H").to_i
      start_minute = @reservation.start_time.strftime("%M").to_i
      end_hour = @reservation.end_time.strftime("%H").to_i
      end_minute = @reservation.end_time.strftime("%M").to_i
      start_day = @reservation.start_time.to_date
      end_day = @reservation.end_time.to_date
      day_diff = (end_day - start_day).to_i
      all_days = schedule.all_occurrences
      prev_reserv = @reservation
      next_reserv = nil
      all_days.shift
      all_days.each do |day|
        next_reservation = prev_reserv.dup
        if (day.to_time + 2.hour).dst?
          next_reservation.start_time = DateTime.new(day.year, day.month, day.day, start_hour, start_minute, 0, 'EDT')
        else
          next_reservation.start_time = DateTime.new(day.year, day.month, day.day, start_hour, start_minute, 0, 'EST')
        end
        day_end = day + day_diff.day
        if (day_end.to_time + 2.hour).dst?
          next_reservation.end_time = DateTime.new(day_end.year, day_end.month, day_end.day, end_hour, end_minute, 0, 'EDT')
        else
          next_reservation.end_time = DateTime.new(day_end.year, day_end.month, day_end.day, end_hour, end_minute, 0, 'EST')
        end
        next_reservation.prev = prev_reserv.id
        # check if there are start_time..end_time for @reservation.car is available on start_day
        unless available?(@reservation.car, next_reservation.start_time..next_reservation.end_time)
          conflict_days_message += show_date_with_month_name(day) + "; "
        end
        next_reservation.save
        if prev_reserv.passengers.present?
          next_reservation.passengers << prev_reserv.passengers
        end
        if prev_reserv.passengers_managers.present?
          next_reservation.passengers_managers << prev_reserv.passengers_managers
        end
        prev_reserv.update(next: next_reservation.id)
        prev_reserv = Reservation.find(next_reservation.id)
      end
    end
    if conflict_days_message.present?
      conflict_days_message = "There are conflicts with other reservations on: " + conflict_days_message
    end
    return conflict_days_message
  end

  def update_this_and_following(update_params, start_time, end_time, admin = false)
    conflict_days_message = ""
    alert = ""
    list = get_following
    conflict_days_message = conflicts_updating_recurring(start_time, end_time)
    if admin || (!admin && conflict_days_message == "")
      list.each do |id|
        reservation = Reservation.find(id)
        day_start = reservation.start_time.beginning_of_day
        day_end = reservation.end_time.beginning_of_day
        start_time = combine_day_and_time(day_start, start_time)
        end_time = combine_day_and_time(day_end, end_time)
        update_params["start_time"] = start_time
        update_params["end_time"] = end_time
        unless reservation.update(update_params)
          alert += "Reservation #{id} was not updated: " + reservation.errors.full_messages.join(',') + ". "
        end
      end
    end
    return conflict_days_message + alert
  end

  def conflicts_updating_recurring(start_time, end_time)
    conflict_days_message = ""
    list = get_following
    list.each do |id|
      reservation = Reservation.find(id)
      day_start = reservation.start_time.beginning_of_day
      day_end = reservation.end_time.beginning_of_day
      start_time = combine_day_and_time(day_start, start_time)
      end_time = combine_day_and_time(day_end, end_time)
      unless available_edit?(id, reservation.car, start_time..end_time)
        conflict_days_message += show_date_with_month_name(day_start) + "; "
      end
    end
    if conflict_days_message.present?
      conflict_days_message = "There are conflicts with other reservations on: " + conflict_days_message
    end
    return conflict_days_message
  end

  # def update_drivers(params)
  #   list = get_following
  #   note = ""
  #   driver_param = params[:driver_id].split("-")
  #   driver_type = driver_param[1]
  #   driver_id = driver_param[0].to_i
  #   if driver_type == "student"
  #     params["driver_id"] = driver_id
  #   elsif driver_type == "manager"
  #     params["driver_manager_id"] = driver_id
  #     params["driver_id"] = nil
  #   end
  #   list.each do |id|
  #     reservation = Reservation.find(id)
  #     unless reservation.update(params)
  #       note += " Reservation #{id} was not updated: " + reservation.errors.full_messages.join(',') + ". "
  #     end
  #   end
  #   if note == ""
  #     note = "Drivers were updated for this and following recurring reservations."
  #   end
  #   return note
  # end

  def add_driver(driver, model, driver_emails, current_user)
    list = get_following
    note = ""
    list.each do |id|
      reservation = Reservation.find(id)
      if model == "student"
        unless reservation.update(driver_id: driver.id, driver_manager_id: nil, updated_by: current_user.id)
          note += " Reservation #{id} was not updated: " + reservation.errors.full_messages.join(',') + ". "
        end
      else
        unless reservation.update(driver_manager_id: driver.id, driver_id: nil, updated_by: current_user.id)
          note += " Reservation #{id} was not updated: " + reservation.errors.full_messages.join(',') + ". "
        end
      end
      driver_emails << reservation_drivers_emails(reservation)
      ReservationMailer.with(reservation: reservation, user: current_user, recurring: true).car_reservation_drivers_edited(driver_emails.flatten).deliver_now
    end
    return note
  end

  def reservation_drivers_emails(reservation)
    emails = []
    if reservation.driver.present?
      emails << email_address(reservation.driver)
    end
    if reservation.backup_driver.present?
      emails << email_address(reservation.backup_driver)
    end
    if reservation.driver_manager.present?
      emails << email_address(reservation.driver_manager)
    end
    return emails
  end

  def make_driver_following_reservations(passenger, model, current_user)
    note = ""
    list = get_following
    list.each do |id|
      reservation = Reservation.find(id)
      # remove from passengers
      if model == 'student'
        reservation.passengers.delete(passenger)
      else
        reservation.passengers_managers.delete(passenger)
      end
      # add current driver to passengers
      if reservation.driver.present?
        reservation.passengers << reservation.driver
      elsif reservation.driver_manager.present?
        reservation.passengers_managers << reservation.driver_manager
      end
      # add as a driver
      if model == 'student'
        unless reservation.update(driver_id: passenger.id, driver_manager_id: nil, updated_by: current_user.id)
          note += "Error updating reservation with ID = " + reservation.id + ". Please report an issue."
        end
      else
        unless reservation.update(driver_manager_id: passenger.id, driver_id: nil, updated_by: current_user.id)
          note += "Error updating reservation with ID = " + reservation.id + ". Please report an issue."
        end
      end
    end
    return note
  end

  def add_passenger_following_reservations(passenger, model)
    list = get_following
    list.each do |id|
      reservation = Reservation.find(id)
      if model == 'student'
        reservation.passengers << passenger
      else
        reservation.passengers_managers << passenger
      end
    end
  end

  def remove_passenger_following_reservations(passenger, model)
    list = get_following
    list.each do |id|
      reservation = Reservation.find(id)
      if model == 'student'
        reservation.passengers.delete(passenger)
      else
        reservation.passengers_managers.delete(passenger)
      end
    end
  end

  def destroy_passengers(result)
    result.each do |id|
      reservation = Reservation.find(id)
      if reservation.passengers.present?
        reservation.passengers.delete_all
      end
      if reservation.passengers_managers.present?
        reservation.passengers_managers.delete_all
      end
    end
  end

  def get_one_to_cancel
    if prev_reservation && next_reservation
      next_reservation.update(prev: prev_reservation.id)
      prev_reservation.update(next: next_reservation.id)
    elsif prev_reservation
      prev_reservation.update(next: nil)
    elsif next_reservation
      next_reservation.update(prev: nil)
    end
    return Array(@reservation.id)
  end

  def remove_from_list
    note = ""
    if prev_reservation && next_reservation
      unless next_reservation.update(prev: prev_reservation.id)
        note += " Error removing reservation #{id} from the recurring list: " + reservation.errors.full_messages.join(',') + ". "
      end
      unless prev_reservation.update(next: next_reservation.id)
        note += " Error removing reservation #{id} from the recurring list: " + reservation.errors.full_messages.join(',') + ". "
      end
    elsif prev_reservation
      unless prev_reservation.update(next: nil)
        note += " Error removing reservation #{id} from the recurring list: " + reservation.errors.full_messages.join(',') + ". "
      end
    elsif next_reservation
      unless next_reservation.update(prev: nil)
        note += " Error removing reservation #{id} from the recurring list: " + reservation.errors.full_messages.join(',') + ". "
      end
    end
    unless @reservation.update(recurring: nil, prev: nil, next: nil)
      note += " Error removing reservation #{id} from the recurring list: " + reservation.errors.full_messages.join(',') + ". "
    end
    return note
  end

  def get_following_to_cancel
    if prev_reservation.present?
      prev_reservation.update(next: nil)
    end
    list = Array(@reservation.id)
    next_id = @reservation.next
    until next_id.nil? do
      reserv = Reservation.find(next_id)
      list << reserv.id
      next_id = reserv.next
    end
    return list
  end

  def get_following
    list = Array(@reservation.id)
    next_id = @reservation.next
    until next_id.nil? do
      reserv = Reservation.find(next_id)
      list << reserv.id
      next_id = reserv.next
    end
    return list
  end

  def get_all_reservations
    list = Array(first_reservation.id)
    next_id = first_reservation.next
    until next_id.nil? do
      reserv = Reservation.find(next_id)
      list << reserv.id
      next_id = reserv.next
    end
    return list
  end

  def schedule
    day = @reservation.start_time.to_date
    schedule = @reservation.schedule(day)
    return schedule
  end

end
