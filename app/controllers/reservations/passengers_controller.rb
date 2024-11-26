class Reservations::PassengersController < ApplicationController
  before_action :set_reservation

  def add_passengers
    @passengers = @reservation.passengers
    @students = @reservation.program.students.order(:last_name) - @passengers
    @students.delete(@reservation.driver)
    @students.delete(@reservation.backup_driver)
    @drivers = []
    @students.map { |s| @drivers << s if s.can_reserve_car? }
    @passengers_managers = @reservation.passengers_managers
    @managers = @reservation.program.managers.to_a
    @managers << @reservation.program.instructor
    @managers = @managers - @passengers_managers
    @managers.delete(@reservation.driver_manager)
    @manager_drivers = []
    @managers.map { |m| @manager_drivers << m if m.can_reserve_car? }
  end

  def add_drivers_and_passengers
    @passengers = @reservation.passengers
    @students = @reservation.program.students.order(:last_name) - @passengers
    @students.delete(@reservation.driver)
    @students.delete(@reservation.backup_driver)
    @drivers = []
    @students.map { |s| @drivers << s if s.can_reserve_car? }
    @passengers_managers = @reservation.passengers_managers
    @managers = @reservation.program.managers.to_a
    @managers << @reservation.program.instructor
    @managers = @managers - @passengers_managers
    @managers.delete(@reservation.driver_manager)
    @manager_drivers = []
    @managers.map { |m| @manager_drivers << m if m.can_reserve_car? }
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
      redirect_to(root_path, notice: "You were removed from the reservation.")
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
    if params[:recurring] == "true"
      recurring_reservation =  RecurringReservation.new(@reservation)
      note = recurring_reservation.make_driver_following_reservations(passenger, model, current_user)
      recurring = true
      if note 
        flash.now[:alert] = note
      end
    else
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
      # add as a driver
      if model == 'student'
        unless @reservation.update(driver_id: passenger.id, driver_manager_id: nil, updated_by: current_user.id)
          flash.now[:alert] = " Reservation #{id} was not updated: " + reservation.errors.full_messages.join(',') + ". Please report an issue."
        end
      else
        unless @reservation.update(driver_manager_id: passenger.id, driver_id: nil, updated_by: current_user.id)
          flash.now[:alert] = " Reservation #{id} was not updated: " + reservation.errors.full_messages.join(',') + ". Please report an issue."
        end
      end
    end
    @reservation = Reservation.find(params[:reservation_id])
    add_passengers
  end

  def add_driver
    session[:return_to] = request.referer
    notice = ""
    alert == ""
    model = params[:model]
    driver = model.classify.constantize.find(params[:id])
    authorize([@reservation, :passenger])
    recurring = false
    if params[:edit] == "true"
      # editing reservation
       #  old drivers emails
      driver_emails = reservation_drivers_emails
      if params[:recurring].empty? && @reservation.recurring.present?
        # edit recuring reservation as a stand-alone; remove it from the recurring set
        recurring_reservation = RecurringReservation.new(@reservation)
        alert = recurring_reservation.remove_from_list
        if alert == ""
          notice += " Reservation was removed from the list of recurring reservations."
        end
      elsif params[:recurring] == "true"
        recurring_reservation = RecurringReservation.new(@reservation)
        recurring = true
        notice = recurring_reservation.add_driver(driver, model, driver_emails, current_user)
      else
        if model == 'student'
          if @reservation.update(driver_id: driver.id, driver_manager_id: nil, updated_by: current_user.id)
            #  new drivers emails
            driver_emails << reservation_drivers_emails
            ReservationMailer.with(reservation: @reservation, user: current_user, recurring: recurring).car_reservation_drivers_edited(driver_emails).deliver_now
          else 
            redirect_back_or_default(" Reservation was not updated: " + @reservation.errors.full_messages.join(',') + ". Please report an issue.", true)
          end
        else
          if @reservation.update(driver_manager_id: driver.id, driver_id: nil, updated_by: current_user.id)
            #  new drivers emails
            driver_emails << reservation_drivers_emails
            ReservationMailer.with(reservation: @reservation, user: current_user, recurring: recurring).car_reservation_drivers_edited(driver_emails).deliver_now
          else
            redirect_back_or_default(" Reservation was not updated: " + @reservation.errors.full_messages.join(',') + ". Please report an issue.", true)
          end
        end
      end
    else
      #  new reservation; no need to check if it's recurring
      if model == 'student'
        unless @reservation.update(driver_id: driver.id, driver_manager_id: nil, updated_by: current_user.id)
          redirect_back_or_default(" Reservation was not updated: " + @reservation.errors.full_messages.join(',') + ". Please report an issue.", true)
        end
      else
        unless @reservation.update(driver_manager_id: driver.id, driver_id: nil, updated_by: current_user.id)
          redirect_back_or_default(" Reservation was not updated: " + @reservation.errors.full_messages.join(',') + ". Please report an issue.", true)
        end
      end
    end
    if notice.present?
      flash.now[:alert] = notice
    end
    if is_admin? || is_in_reservation?(current_user, @reservation)
      add_passengers
    else 
      redirect_to(root_path, notice: "You were removed from the reservation.")
      return
    end
  end

  private

  def set_reservation
    @reservation = Reservation.find(params[:reservation_id])
  end

  def reservation_drivers_emails
    emails = []
    if @reservation.driver.present?
      emails << email_address(@reservation.driver)
    end
    if @reservation.backup_driver.present?
      emails << email_address(@reservation.backup_driver)
    end
    if @reservation.driver_manager.present?
      emails << email_address(@reservation.driver_manager)
    end
    return emails
  end
end
