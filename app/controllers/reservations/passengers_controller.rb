class Reservations::PassengersController < ApplicationController
  before_action :set_reservation

  def add_passengers
    @passengers = @reservation.passengers
    @students = @reservation.program.students.order(:last_name) - @passengers
    @students.delete(@reservation.driver)
    @students.delete(@reservation.backup_driver)
    @passengers_managers = @reservation.passengers_managers
    @managers = @reservation.program.managers.to_a
    @managers << @reservation.program.instructor
    @managers = @managers - @passengers_managers
    @managers.delete(@reservation.driver_manager)
    authorize([@reservation, :passenger]) 
  end

  def add_passenger
    authorize([@reservation, :passenger])
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
  def add_passenger_manager
    authorize([@reservation, :passenger])
    if params[:manager_id].present?
      if params[:recurring] == "true"
        recurring_reservation =  RecurringReservation.new(@reservation)
        recurring_reservation.add_passenger_manager_following_reservations(Manager.find(params[:manager_id]))
      else
        @reservation.passengers_managers << Manager.find(params[:manager_id])
      end
      redirect_to add_passengers_path(@reservation, :edit => params[:edit], :recurring => params[:recurring])
    end
  end


  def remove_passenger
    model = params[:resource]
    passenger = model.classify.constantize.find(params[:id])
    authorize([@reservation, :passenger])
    recurring = false
    if params[:recurring] == "true"
      recurring_reservation =  RecurringReservation.new(@reservation)
      recurring_reservation.remove_passenger_following_reservations(passenger)
      recurring = true
    else
      if model == 'student'
       @reservation.passengers.delete(passenger)
      else
        @reservation.passengers_managers.delete(passenger)
      end
    end
    # send email only if reservation confirmation email has been sent already; if a passenger is removed for a new reservation - do not sent an email
    if EmailLog.find_by(email_type: "confirmation", sent_from_model: "Reservation", record_id: @reservation)
      ReservationMailer.with(reservation: @reservation).car_reservation_remove_passenger(passenger, current_user, recurring).deliver_now
    end
    add_passengers
  end

  private

  def set_reservation
    @reservation = Reservation.find(params[:reservation_id])
  end
end
