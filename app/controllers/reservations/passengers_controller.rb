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

  def add_drivers_and_passengers
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
    model = params[:model]
    passenger = model.classify.constantize.find(params[:id])
    authorize([@reservation, :passenger])
    if params[:recurring] == "true"
      recurring_reservation =  RecurringReservation.new(@reservation)
      recurring_reservation.add_passenger_following_reservations(passenger, model)
    else
      if model == 'student'
        @reservation.passengers << passenger
      else
        @reservation.passengers_managers << passenger
      end
    end
    redirect_to add_drivers_and_passengers_path(@reservation, :edit => params[:edit], :recurring => params[:recurring])
  end

  def remove_passenger
    model = params[:resource]
    passenger = model.classify.constantize.find(params[:id])
    authorize([@reservation, :passenger])
    recurring = false
    if params[:recurring] == "true"
      recurring_reservation =  RecurringReservation.new(@reservation)
      recurring_reservation.remove_passenger_following_reservations(passenger, model)
      recurring = true
    else
      if model == 'student'
        @reservation.passengers.delete(passenger)
      else
        @reservation.passengers_managers.delete(passenger)
      end
    end
    # send email only if reservation confirmation email has been sent already; if a passenger is removed for a new reservation - do not sent an email
    if EmailLog.find_by(email_type: "confirmation", sent_from_model: "Reservation", record_id: @reservation) || EmailLog.find_by(email_type: "recurring_confirmation", sent_from_model: "Reservation", record_id: @reservation)
      ReservationMailer.with(reservation: @reservation, user: current_user, recurring: recurring).car_reservation_remove_passenger(passenger).deliver_now
    end
    if current_user.uniqname == passenger.uniqname
      redirect_to(root_path, notice: "You were removed for the reservation.")
      return
    end
    add_passengers
  end

  def make_driver
    model = params[:model]
    passenger = model.classify.constantize.find(params[:id])
    authorize([@reservation, :passenger])
    recurring = false
    # remove from passengers
    if model == 'student'
      @reservation.passengers.delete(passenger)
    else
      @reservation.passengers_managers.delete(passenger)
    end
    # add current driver to passengers
    if @reservation.driver.present?
      @reservation.passengers << @reservation.driver
    elsif @reservation.driver_manager.present?
      @reservation.passengers_managers << @reservation.driver_manager
    end
    #  add as a driver
    if model == 'student'
      unless @reservation.update(driver_id: passenger.id, driver_manager_id: nil)
        fail
      end
    else
      unless @reservation.update(driver_manager_id: passenger.id, driver_id: nil)
        fail
      end
    end
    add_passengers
  end

  def add_driver
    model = params[:model]
    driver = model.classify.constantize.find(params[:id])
    authorize([@reservation, :passenger])
    recurring = false
    if model == 'student' 
      if @reservation.driver_manager.present? || @reservation.driver.present?
        if @reservation.update(driver_id: driver.id, driver_manager_id: nil)
          # send email that driver was removed
        else 
          fail
        end
      else
        unless @reservation.update(driver_id: driver.id)
          fail
        end
      end
    else
      if @reservation.driver_manager.present? || @reservation.driver.present?
        if @reservation.update(driver_manager_id: driver.id, driver_id: nil)
          # send email that driver was removed
        else
          fail
        end
      end
    end
    add_passengers
  end

  private

  def set_reservation
    @reservation = Reservation.find(params[:reservation_id])
  end
end
