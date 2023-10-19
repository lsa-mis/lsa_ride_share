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
        next_reservation.save
        if prev_reserv.passengers.present?
          next_reservation.passengers << prev_reserv.passengers
        end
        prev_reserv.update(next: next_reservation.id)
        prev_reserv = Reservation.find(next_reservation.id)
      end
    end
  end

  def update_drivers(params)
    list = get_following
    note = ""
    list.each do |id|
      reservation = Reservation.find(id)
      unless reservation.update(params)
        note += " Reservation #{id} was not updated: " + reservation.errors.full_messages.join(',') + ". "
      end
    end
    if note == ""
      note = "Drivers were updated for this and following recurring reservations."
    end
    return note
  end

  def add_passenger_following_reservations(student)
    list = get_following
    list.each do |id|
      reservation = Reservation.find(id)
      reservation.passengers << student
    end
  end

  def remove_passenger_following_reservations(student)
    list = get_following
    list.each do |id|
      reservation = Reservation.find(id)
      reservation.passengers.delete(student)
    end
  end

  def get_one_to_delete
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

  def get_following_to_delete
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
