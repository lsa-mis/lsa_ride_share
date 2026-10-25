class RecurringReservation
  include ActionView::Helpers::SanitizeHelper
  include ApplicationHelper

  def initialize(reservation)
    @reservation = reservation
  end

  def reservation
    @reservation
  end

  def first_reservation(links = chain)
    current = @reservation
    visited = [current.id]
    while current.prev.present? && !visited.include?(current.prev)
      previous_reservation = links[current.prev]
      break unless previous_reservation&.next == current.id
      current = previous_reservation
      visited << current.id
    end
    current
  end

  def last_reservation(links = chain)
    current = @reservation
    visited = [current.id]
    while current.next.present? && !visited.include?(current.next)
      next_reservation = links[current.next]
      break unless next_reservation&.prev == current.id
      current = next_reservation
      visited << current.id
    end
    current
  end

  # the rule of the first reservation in the chain that has one; a corrupted reservation can lose its rule
  def rule
    links = chain
    current = first_reservation(links)
    visited = []
    while current.present? && !visited.include?(current.id)
      return current.rule if current.recurring.present?
      visited << current.id
      next_reservation = current.next.present? ? links[current.next] : nil
      current = next_reservation&.prev == current.id ? next_reservation : nil
    end
    nil
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
    failed_days_message = ""
    # the series was already created for this reservation (e.g. a double submit)
    return conflict_days_message if @reservation.next.present?
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
        conflicting = conflicting_reservations(@reservation.car, next_reservation.start_time..next_reservation.end_time).to_a
        next_reservation.status = conflicting.present? ? CONFLICT_STATUS : nil
        created = Reservation.transaction do
          next_reservation.save!
          conflicting.each { |reservation| reservation.update!(status: CONFLICT_STATUS) }
          if prev_reserv.passengers.present?
            next_reservation.passengers << prev_reserv.passengers
          end
          if prev_reserv.passengers_managers.present?
            next_reservation.passengers_managers << prev_reserv.passengers_managers
          end
          prev_reserv.update!(next: next_reservation.id)
          true
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
          raise ActiveRecord::Rollback
        end
        unless created
          failed_days_message += show_date_with_month_name(day) + "; "
          next
        end
        conflict_days_message += show_date_with_month_name(day) + "; " if conflicting.present?
        prev_reserv = Reservation.find(next_reservation.id)
      end
    end
    if conflict_days_message.present?
      conflict_days_message = "There are conflicts with other reservations on: " + conflict_days_message
    end
    if failed_days_message.present?
      conflict_days_message += " Reservations were not created on: " + failed_days_message
    end
    return conflict_days_message
  end

  def update_this_and_following(update_params, start_time, end_time, admin = false)
    conflict_days_message = ""
    alert = ""
    reservations = following_reservations
    car_changed = update_params.key?("car_id")
    new_car = Car.find(update_params["car_id"]) if car_changed && update_params["car_id"].present?
    # assign associations, not ids, so validations don't reload the same car and site for every reservation
    attributes = update_params.except("car_id", "site_id")
    attributes["car"] = new_car if car_changed
    attributes["site"] = Site.find_by(id: update_params["site_id"]) if update_params.key?("site_id")
    new_ranges = reservations.map { |reservation| new_time_range(reservation, start_time, end_time) }
    candidates = conflict_candidates(reservations, new_ranges, new_car)
    conflict_days_message = conflicts_updating_recurring(start_time, end_time, new_car, car_changed, reservations, candidates)
    if admin || (!admin && conflict_days_message == "")
      reservations.zip(new_ranges).each do |reservation, new_range|
        id = reservation.id
        attributes["start_time"] = new_range.begin
        attributes["end_time"] = new_range.end
        previously_conflicting = conflicts_among(candidates, reservation.car, reservation.start_time..reservation.end_time, id)
        conflicting = conflicts_among(candidates, car_changed ? new_car : reservation.car, new_range, id)
        attributes["status"] = conflicting.present? ? CONFLICT_STATUS : nil
        failed_record = nil
        Reservation.transaction do
          reservation.update!(attributes)
          conflicting.each { |conflicting_reservation| conflicting_reservation.update!(status: CONFLICT_STATUS) }
          clear_resolved_conflicts(previously_conflicting - conflicting)
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
          failed_record = e.record
          raise ActiveRecord::Rollback
        end
        if failed_record == reservation
          alert += "Reservation #{id} was not updated: " + reservation.errors.full_messages.join(',') + ". "
        elsif failed_record
          alert += "Reservation #{id} was not updated: could not update the conflict status of reservation #{failed_record.id}: " + failed_record.errors.full_messages.join(',') + ". "
        end
        # the rollback leaves the in-memory candidates out of sync with the database
        ([reservation] + conflicting).each(&:reload) if failed_record
      end
    end
    return conflict_days_message + alert
  end

  def conflicts_updating_recurring(start_time, end_time, new_car = nil, car_changed = false, reservations = following_reservations, candidates = nil)
    conflict_days_message = ""
    new_ranges = reservations.map { |reservation| new_time_range(reservation, start_time, end_time) }
    candidates ||= conflict_candidates(reservations, new_ranges, new_car)
    reservations.zip(new_ranges).each do |reservation, new_range|
      if conflicts_among(candidates, car_changed ? new_car : reservation.car, new_range, reservation.id).present?
        conflict_days_message += show_date_with_month_name(reservation.start_time.beginning_of_day) + "; "
      end
    end
    if conflict_days_message.present?
      conflict_days_message = "There are conflicts with other reservations on: " + conflict_days_message
    end
    return conflict_days_message
  end

  # this and following reservations, in order, with what their validations load
  def following_reservations
    ids = get_following
    Reservation.includes(:car, :program, :site, :passengers, :passengers_managers, :driver, :driver_manager).where(id: ids).index_by(&:id).values_at(*ids).compact
  end

  # the reservation's own days at the times of day of start_time and end_time
  def new_time_range(reservation, start_time, end_time)
    combine_day_and_time(reservation.start_time.beginning_of_day, start_time)..combine_day_and_time(reservation.end_time.beginning_of_day, end_time)
  end

  # every reservation of the series' cars and new_car that can overlap the series' current or new times, in one query;
  # series reservations are the same objects as in reservations, so updating them keeps the candidates current
  def conflict_candidates(reservations, new_ranges, new_car = nil)
    car_ids = (reservations.map(&:car_id) + [new_car&.id]).compact.uniq
    return reservations if car_ids.empty?
    ranges = reservations.map { |reservation| reservation.start_time..reservation.end_time } + new_ranges
    window_begin = ranges.map { |range| [range.begin + 1.minute, range.end - 1.minute].min }.min
    window_end = ranges.map { |range| [range.begin + 1.minute, range.end - 1.minute].max }.max
    series = reservations.index_by(&:id)
    others = Reservation.includes(:car, :program, :site).where(car_id: car_ids).where.not(id: series.keys).where(
      "(start_time BETWEEN :window_begin AND :window_end OR end_time BETWEEN :window_begin AND :window_end) OR (start_time < :window_end AND end_time > :window_begin)",
      window_begin: window_begin, window_end: window_end
    )
    reservations + others.to_a
  end

  # in-memory version of conflicting_reservations(car, range, except_id) over the candidates
  def conflicts_among(candidates, car, range, except_id)
    return [] unless car.present?
    range_begin = range.begin + 1.minute
    range_end = range.end - 1.minute
    candidates.select do |candidate|
      next false if candidate.car_id != car.id || candidate.id == except_id
      next false if candidate.start_time.nil? || candidate.end_time.nil?
      candidate.start_time.between?(range_begin, range_end) || candidate.end_time.between?(range_begin, range_end) ||
        (candidate.start_time < range_begin && candidate.end_time > range_end)
    end
  end

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
    following_ids(@reservation)
  end

  def get_following
    following_ids(@reservation)
  end

  def get_all_reservations
    following_ids(first_reservation)
  end

  # ids of start and every reservation linked after it; stops before revisiting an id
  def following_ids(start)
    links = chain
    list = Array(start.id)
    next_id = start.next
    until next_id.nil? || list.include?(next_id) do
      reserv = links[next_id] || Reservation.find(next_id)
      list << reserv.id
      next_id = reserv.next
    end
    return list
  end

  # every not canceled reservation reachable from @reservation through prev/next ids, loaded in one query, by id
  def chain
    chain_ids = <<~SQL.squish
      WITH RECURSIVE chain AS (
        SELECT id, prev, next FROM reservations WHERE id = :id
        UNION
        SELECT r.id, r.prev, r.next FROM reservations r
        JOIN chain c ON r.id = c.prev OR r.id = c.next
        WHERE r.canceled = FALSE
      )
      SELECT id FROM chain
    SQL
    links = Reservation.where("reservations.id IN (#{chain_ids})", id: @reservation.id).index_by(&:id)
    links.merge(@reservation.id => @reservation)
  end

  def schedule
    day = @reservation.start_time.to_date
    schedule = @reservation.schedule(day)
    return schedule
  end

end
