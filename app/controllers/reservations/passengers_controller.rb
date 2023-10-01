class Reservations::PassengersController < ApplicationController
  before_action :set_reservation

  def add_passengers
    @passengers = @reservation.passengers
    @students = @reservation.program.students.order(:last_name) - @passengers
    @students.delete(@reservation.driver)
    @students.delete(@reservation.backup_driver)
    authorize([@reservation, @passengers]) 
  end

  def add_passenger
    authorize([@reservation, Student])
    if params[:student_id].present?
      if params[:recurring] == "true"
        recurring_reservation =  RecurringReservation.new(@reservation)
        recurring_reservation.add_passenger_following_reservations(Student.find(params[:student_id]))
      else
        @reservation.passengers << Student.find(params[:student_id])
      end
      redirect_to add_passengers_path(@reservation, :edit => params[:edit], :recurring => params[:recurring])
    end
  end

  def remove_passenger
    authorize([@reservation, Student])
    recurring = false
    if params[:recurring] == "true"
      recurring_reservation =  RecurringReservation.new(@reservation)
      recurring_reservation.remove_passenger_following_reservations(Student.find(params[:student_id]))
      recurring = true
    else
      @reservation.passengers.delete(Student.find(params[:student_id]))
    end
    # send email only if reservation confirmation email has been sent already; if a passenger is removed for a new reservation - do not sent an email
    if EmailLog.find_by(email_type: "confirmation", sent_from_model: "Reservation", record_id: @reservation)
      ReservationMailer.with(reservation: @reservation).car_reservation_remove_passenger(Student.find(params[:student_id]), current_user).deliver_now
    end
    add_passengers
  end

  private

  def set_reservation
    @reservation = Reservation.find(params[:reservation_id])
  end
end
