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

  def start_on
    show_date_time(first_reservation.start_time)
  end

  def end_on
    show_date_time(last_reservation.end_time)
  end

  def create_all
    unless @reservation.recurring.empty?
      start_time = @reservation.start_time.strftime("%I:%M%p")
      end_time = @reservation.end_time.strftime("%I:%M%p")
      all_days = schedule.all_occurrences
      prev_reserv = @reservation
      next_reserv = nil
      all_days.shift
      all_days.each do |day|
        next_reservation = prev_reserv.dup
        next_reservation.start_time = day + Time.parse(start_time).seconds_since_midnight.seconds
        next_reservation.end_time = day + Time.parse(end_time).seconds_since_midnight.seconds
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

  def schedule
    day = @reservation.start_time.to_date
    schedule = @reservation.schedule(day)
    return schedule
  end

  def count
    @reservation.rule.validations.count
  end

end