class ReservationsController < ApplicationController
  before_action :auth_user
  before_action :set_calendar_reservations, only: %i[ index week_calendar ]
  before_action :set_reservation, only: %i[ show edit update destroy add_drivers add_passengers remove_passenger 
    finish_reservation update_passengers send_reservation_updated_email cancel_reason cancel_reservation cancel_recurring_reservation 
    add_drivers_later approve_all_recurring edit_long add_edit_drivers get_drivers_list]
  before_action :set_terms_and_units
  before_action :set_programs
  before_action :set_cars, only: %i[ new new_long get_available_cars get_available_cars_long ]
  before_action :set_number_of_seats, only: %i[ new new_long create edit edit_long ]

  # GET /reservations or /reservations.json
  def index
    authorize @reservations
  end

  def week_calendar
    @no_car = false
    authorize Reservation
    @hour_begin = UnitPreference.find_by(name: "reservation_time_begin", unit_id: @unit_id).value.split(":").first.to_i - 1
    @hour_end = UnitPreference.find_by(name: "reservation_time_end", unit_id: @unit_id).value.split(":").first.to_i + 12
    authorize @reservations
    @cars = Car.available.where(unit_id: @unit_id).order(:car_number)
    @date_range = Date.today.beginning_of_week..Date.today.end_of_week
    @dates = @date_range.to_a
  end

  def day_reservations
    @reservations = Reservation.where(program: Program.where(unit_id: session[:unit_ids]))
    @day = params[:date].to_date
    @day_reservations = @reservations.where("(start_time BETWEEN ? AND ?) OR (start_time < ? AND end_time > ?)", @day.beginning_of_day, @day.end_of_day, @day.end_of_day, @day.beginning_of_day).order(:start_time)
    authorize @day_reservations
  end

  def canceled_reservations
    @terms = Term.sorted

    if params[:unit_id].present?
      @programs = Program.where(unit_id: params[:unit_id])
    else
      @programs = Program.where(unit_id: session[:unit_ids])
    end
    @programs = @programs.data(params[:term_id])
    program_ids = @programs.pluck(:id)
    @canceled_reservations = Reservation.canceled.where(program_id: program_ids).page(params[:page])

    if params[:program_id].present?
      @canceled_reservations = @canceled_reservations.where(program_id: params[:program_id])
    end

    authorize @canceled_reservations
  end

  def selected_reservations
    @selected_reservations = params[:res_ids].keys.join(',')
    @day = params[:day]
    authorize Reservation
    render :email_form, status: 422
  end

  def send_email_to_selected_reservations
    @selected_reservations = params[:selected_reservations].split(',').map(&:to_i)
    subject = params[:subject]
    message = params[:message]
    day = params[:day].to_date
    authorize Reservation
    @selected_reservations.each do |id|
      reservation = Reservation.find(id)
      ReservationMailer.with(reservation: reservation, subject: subject, message: message, user: current_user).to_selected_reservations.deliver_now
    end
    ReservationMailer.with(subject: subject, message: message, user: current_user).to_selected_reservations_copy_to_admin(@selected_reservations).deliver_now
    redirect_to day_reservations_path(day), notice: "Emails were sent." 
  end

  # GET /reservations/1 or /reservations/1.json
  def show
    @passengers = @reservation.passengers + @reservation.passengers_managers
    @email_log_entries = EmailLog.where(sent_from_model: "Reservation", record_id: @reservation.id).order(created_at: :desc)
    authorize @reservation
  end

  # GET /reservations/new
  def new
    @reservation = Reservation.new
    @term_id = Term.current.present? ? Term.current[0].id : nil
    authorize @reservation
    if is_manager?
      @program = Program.find(params[:program_id])
      get_data_for_program(@program)
    elsif is_student?
      @program = Student.find(params[:student_id]).program
      get_data_for_program(@program)
    elsif params[:unit_id].present?
      @unit_id = params[:unit_id]
      @min_date = DateTime.now
    else
      flash.now[:alert] = 'You must select a unit first.'
      render turbo_stream: turbo_stream.update("flash", partial: "layouts/notification")
    end
    if params[:day_start].present?
      @day_start = params[:day_start].to_date
    else
      @day_start = default_reservation_for_students(@unit_id)
    end
    if params[:term_id].present?
      @term_id = params[:term_id]
    end
    if @term_id.present? && @unit_id.present?
      @programs = Program.where(unit_id: @unit_id, term: @term_id).order(:title, :catalog_number, :class_section)
    end
    if params[:car_id].present?
      @car_id = params[:car_id]
    end
    if params[:start_time].present?
      @start_time = params[:start_time]
    elsif @day_start == Date.today
      @start_time = unit_beginning_of_day(@day_start, @unit_id)
      if @start_time < DateTime.now
        @start_time = Time.at(((DateTime.now + 450.second).to_f / 15.minute).round * 15.minute).to_datetime
        @end_time = @start_time + 15.minute
      end
    end
    if is_admin?
      @sites = []
    end
    @until_date = max_day_for_reservation(@unit_id)
    @reservation.start_time = @day_start
  end

  def new_long
    new
    if params[:day_end].present?
      @day_end = params[:day_end].to_date
    else
      @day_end = @day_start + 1.day
    end
    @reservation.end_time = @day_end
  end

  # GET /reservations/1/edit
  def edit
    @day_start = @reservation.start_time.to_date
    @unit_id = @reservation.program.unit.id
    @term_id = @reservation.program.term.id
    @car_id = @reservation.car_id
    @start_time = (@reservation.start_time + 15.minute).to_datetime.to_s
    @end_time = (@reservation.end_time - 15.minute).to_datetime.to_s
    @number_of_people_on_trip = @reservation.number_of_people_on_trip
    @cars = Car.available.where(unit_id: @unit_id).order(:car_number)
    @sites = @reservation.program.sites
  end

  def edit_long
    edit
    @day_end = @reservation.end_time.to_date
  end

  def get_available_cars
    if params[:unit_id].present?
      @unit_id = params[:unit_id]
    end
    if params[:day_start].present?
      @day_start = params[:day_start].to_date
    end
    if params[:number].present?
      @cars = @cars.where("number_of_seats >= ?", params[:number]).order(:car_number)
    end
    if params[:start_time].present?
      @start_time = params[:start_time]
      unless @day_start == @start_time.to_date
        @start_time = combine_day_and_time(@day_start, @start_time)
      end
    end
    if params[:end_time].present?
      @end_time = params[:end_time]
      unless @day_start == @end_time.to_date
        @end_time = combine_day_and_time(@day_start, @end_time)
      end
    end
    if ((@end_time.to_datetime - @start_time.to_datetime) * 24 * 60).to_i > 30
      @reserv_begin = @start_time.to_datetime
      @reserv_end = @end_time.to_datetime
      range = @reserv_begin..@reserv_end
      @cars = available_cars(@cars, range)
    end
    if params[:until_date].present?
      @until_date = params[:until_date]
    else
      @until_date = max_day_for_reservation(@unit_id)
    end
    authorize Reservation
  end

  def get_available_cars_long
    if params[:unit_id].present?
      @unit_id = params[:unit_id]
    end
    if params[:day_start].present?
      @day_start = params[:day_start].to_date
    end
    if params[:day_end].present?
      @day_end = params[:day_end].to_date
      if @day_start >= @day_end
        @day_end = @day_start + 1.day
      end
    end
    if params[:start_time].present?
      @start_time = params[:start_time]
      unless @day_start == @start_time.to_date
        @start_time = combine_day_and_time(@day_start, @start_time)
      end
    end
    if params[:end_time].present?
      @end_time = params[:end_time]
      unless @day_end == @end_time.to_date
        @end_time = combine_day_and_time(@day_end, @end_time)
      end
    end
    if params[:number].present?
      @cars = @cars.where("number_of_seats >= ?", params[:number]).order(:car_number)
    end
    if (@day_end.to_date - @day_start.to_date).to_i > 1

      cars_reservations = Reservation.where(car_id: @cars)
      day_start_beginning = unit_beginning_of_day(@day_start, @unit_id) - 15.minute
      day_start_finish = unit_end_of_day(@day_start, @unit_id) + 15.minute

      day_end_beginning = unit_beginning_of_day(@day_end, @unit_id) - 15.minute
      day_end_finish = unit_end_of_day(@day_end, @unit_id) + 15.minute

      long_reservations = cars_reservations.where("start_time < ? AND end_time > ?", day_start_finish, day_end_beginning).pluck(:car_id)
      between_reservations = cars_reservations.where(start_time: (day_start_beginning + 1.day).., end_time: ..(day_end_finish - 1.day)).pluck(:car_id)
      day_start_reservations = cars_reservations.where(start_time: day_start_beginning..day_start_finish, end_time: day_start_finish - 30.minute..day_start_finish).pluck(:car_id)
      day_end_reservations = cars_reservations.where(start_time: day_end_beginning..day_end_beginning + 30.minute, end_time: day_end_beginning..day_end_finish).pluck(:car_id)
      exclude_cars = (between_reservations + day_start_reservations + day_end_reservations + long_reservations).uniq
      @cars = @cars.where.not(id: exclude_cars)
    end
    if params[:until_date].present?
      @until_date = params[:until_date]
    else
      @until_date = max_day_for_reservation(@unit_id)
    end
    authorize Reservation
  end

  def list_of_available_cars(unit_id, day_start, number, start_time, end_time)
    cars = Car.available.data(unit_id).order(:car_number)
    cars = cars.where("number_of_seats >= ?", number)
    
    if ((end_time.to_datetime - start_time.to_datetime) * 24 * 60).to_i > 30
      range = start_time.to_datetime..end_time.to_datetime
    else
      range = day_start.beginning_of_day..day_start.end_of_day
    end
      cars = available_cars(cars, range)
      return cars
  end

  def no_car_all_times
    if params[:unit_id].present?
      @unit_id = params[:unit_id]
    end
    if params[:day_start].present?
      @day_start = params[:day_start].to_date
    end
    @day_start = params[:day_start].to_date
    @start_time = combine_day_and_time(@day_start, params[:start_time])
    @end_time = combine_day_and_time(@day_start, params[:end_time])
    @cars = []
    authorize Reservation
  end

  # POST /reservations or /reservations.json
  def create
    @reservation = Reservation.new(reservation_params)
    if params[:car_id].present?
      @reservation.car_id = params[:car_id]
      @car_id = params[:car_id]
    end
    @reservation.start_time = (params[:start_time]).to_datetime - 15.minute
    @reservation.end_time = (params[:end_time]).to_datetime + 15.minute
    @reservation.number_of_people_on_trip = params[:number_of_people_on_trip]
    @reservation.until_date = params[:until_date]
    @reservation.reserved_by = current_user.id
    authorize @reservation
    # check for conflicts
    if available?(@reservation.car, @reservation.start_time..@reservation.end_time)
      if @reservation.save
        unless is_admin?
          if is_manager?
            driver_manager = Manager.find_by(uniqname: current_user.uniqname)
            @reservation.update(driver_manager_id: driver_manager.id)
          elsif is_student?
            driver = Student.find_by(program_id: @reservation.program_id, uniqname: current_user.uniqname)
            @reservation.update(driver_id: driver.id)
          end
        end
        @students = @reservation.program.students 
        redirect_to add_drivers_and_passengers_path(@reservation), notice: "Please add drivers."
      else
        @program = Program.find(params[:reservation][:program_id])
        @term_id = params[:term_id]
        @sites = @program.sites.order(:title)
        @number_of_people_on_trip = params[:number_of_people_on_trip]
        @day_start = params[:day_start].to_date
        @unit_id = params[:unit_id]
        @car_id = params[:car_id]
        @start_time = params[:start_time]
        @end_time = params[:end_time]
        @until_date = params[:until_date]
        @cars = list_of_available_cars(@unit_id, @day_start, @number_of_people_on_trip, @start_time, @end_time)
        render :new, status: :unprocessable_entity
      end
    else
      flash[:alert] = "There is a conflict with another reservation. Please select different time."
      @program = Program.find(params[:reservation][:program_id])
      @term_id = params[:term_id]
      @sites = @program.sites.order(:title)
      @number_of_people_on_trip = params[:number_of_people_on_trip]
      @day_start = params[:day_start].to_date
      @unit_id = params[:unit_id]
      @car_id = params[:car_id]
      @start_time = params[:start_time]
      @end_time = params[:end_time]
      @until_date = params[:until_date]
      @cars = list_of_available_cars(@unit_id, @day_start, @number_of_people_on_trip, @start_time, @end_time)
      if params[:day_end].present?
        @day_end = params[:day_end].to_date
        render :new_long, status: :unprocessable_entity
      else 
        render :new, status: :unprocessable_entity
      end
    end
  end

  def edit_change_day
    if params[:unit_id].present?
      @unit_id = params[:unit_id]
    end
    if params[:day_start].present?
      @day_start = params[:day_start].to_date
      @start_time = combine_day_and_time(@day_start, params[:start_time])
      @end_time = combine_day_and_time(@day_start, params[:end_time])
    end
    @cars = Car.available.where(unit_id: @unit_id).order(:car_number)
    authorize Reservation
  end

  def change_start_end_day
    if params[:unit_id].present?
      @unit_id = params[:unit_id]
    end
    if params[:day_start].present?
      @day_start = params[:day_start].to_date
      @start_time = combine_day_and_time(@day_start, params[:start_time])
    end
    if params[:day_end].present?
      @day_end = params[:day_end].to_date
      @end_time = combine_day_and_time(@day_end, params[:end_time])
    end
    authorize Reservation
  end

  # PATCH/PUT /reservations/1 or /reservations/1.json
  def update
    notice = ""
    if params[:reservation][:approved].present?
      if @reservation.update(reservation_params)
        ReservationMailer.with(reservation: @reservation, user: current_user).car_reservation_approved.deliver_now unless @reservation.approved == false
        redirect_to reservation_path(@reservation), notice: "Reservation was updated."
        return
      else
        flash.now[:alert] = 'Error approving the reservation'
        render turbo_stream: turbo_stream.update("flash", partial: "layouts/notification")
        return
      end
    end
    if params[:recurring] == "true"
      recurring_reservation = RecurringReservation.new(@reservation)
      update_params = {}
      update_params["site_id"] = reservation_params[:site_id]
      update_params["updated_by"] = reservation_params[:updated_by]
      update_params["car_id"] = params[:car_id]
      update_params["number_of_people_on_trip"] = params[:number_of_people_on_trip]
      start_time = params[:start_time].to_datetime - 15.minute
      end_time = params[:end_time].to_datetime + 15.minute
      notice = "This and all following recurring reservations were updated."
      if is_admin?
        alert = recurring_reservation.update_this_and_following(update_params, start_time, end_time, true)
        redirect_to reservation_path(@reservation), notice: notice, alert: alert
      else
        alert = recurring_reservation.update_this_and_following(update_params, start_time, end_time, false)
        if alert == ""
          ReservationMailer.with(reservation: @reservation, user: current_user, recurring: true).car_reservation_updated(admin: true).deliver_now
          @email_log_entries = EmailLog.where(sent_from_model: "Reservation", record_id: @reservation.id).order(created_at: :desc)
          redirect_to reservation_path(@reservation), notice: notice
        else
          # for students and managers - don't save if there is a conflict
          alert += " please select a different time or ask admins to edit the reservation."
          @programs = Program.where(unit_id: session[:unit_ids]).order(:title, :catalog_number, :class_section)
          @number_of_seats = 1..Car.available.maximum(:number_of_seats)
          @number_of_people_on_trip = Reservation.find(params[:id]).number_of_people_on_trip
          @day_start = @reservation.start_time.to_date
          @unit_id = params[:unit_id]
          @cars = Car.available.where(unit_id: @unit_id).order(:car_number)
          @sites = @reservation.program.sites
          @car_id = @reservation.car_id
          @start_time = params[:start_time]
          @end_time = params[:end_time]
          flash.now[:alert] = alert
          if params[:day_end].present?
            @day_end = params[:day_end].to_date
            render :edit_long, status: :unprocessable_entity
          else 
            render :edit, status: :unprocessable_entity
          end
          return
        end
      end
    else
      if @reservation.recurring.present?
        # edit recurring reservation as stahd-alone; remotve it from the list of recurring reservations
        recurring_reservation = RecurringReservation.new(@reservation)
        alert = recurring_reservation.remove_from_list
        if alert == ""
          notice = " Reservation was removed from the list of recurring reservations."
        else
          redirect_to reservation_path(@reservation), alert: "Reservation was not updated." + alert
          return
        end
      end
      @reservation.attributes = reservation_params
      @reservation.car_id = params[:car_id]
      @reservation.start_time = params[:start_time].to_datetime - 15.minute
      @reservation.end_time = params[:end_time].to_datetime + 15.minute
      @reservation.number_of_people_on_trip = params[:number_of_people_on_trip]
      # check if updated reservation has conflict with existing resertvations
      no_conflict = available_edit?(@reservation.id, @reservation.car, @reservation.start_time..@reservation.end_time)
      if no_conflict
        alert = ""
      elsif !no_conflict && is_admin?
        alert = " There is a conflict with another reservation on " + show_date_with_month_name(@reservation.start_time) + "."
      else
        alert = " There is a conflict with another reservation on " + show_date_with_month_name(@reservation.start_time) + ". Please select a different time or ask admins to edit the reservation."
      end
      # for admins - always save && display message about conflict
      # for non admins - save if there is no conflict
      if is_admin? || !is_admin? && no_conflict
        if @reservation.update(reservation_params)
          unless is_admin?
            ReservationMailer.with(reservation: @reservation, user: current_user, recurring: false).car_reservation_updated(admin: true).deliver_now
            @email_log_entries = EmailLog.where(sent_from_model: "Reservation", record_id: @reservation.id).order(created_at: :desc)
          end
          redirect_to reservation_path(@reservation), notice: "Reservation was successfully updated." + notice, alert: alert
        else
          @programs = Program.where(unit_id: session[:unit_ids]).order(:title, :catalog_number, :class_section)
          @number_of_seats = 1..Car.available.maximum(:number_of_seats)
          @number_of_people_on_trip = Reservation.find(params[:id]).number_of_people_on_trip
          @day_start = params[:day_start].to_date
          @unit_id = params[:unit_id]
          @cars = Car.available.where(unit_id: @unit_id).order(:car_number)
          @sites = @reservation.program.sites
          @car_id = @reservation.car_id
          @start_time = params[:start_time]
          @end_time = params[:end_time]
          if params[:day_end].present?
            @day_end = params[:day_end].to_date
            render :edit_long, status: :unprocessable_entity
          else 
            render :edit, status: :unprocessable_entity
          end
        end
      else
        # for students and managers - don't save if there is a conflict
        @programs = Program.where(unit_id: session[:unit_ids]).order(:title, :catalog_number, :class_section)
        @number_of_seats = 1..Car.available.maximum(:number_of_seats)
        @number_of_people_on_trip = Reservation.find(params[:id]).number_of_people_on_trip
        @day_start = params[:day_start].to_date
        @unit_id = params[:unit_id]
        @cars = Car.available.where(unit_id: @unit_id).order(:car_number)
        @sites = @reservation.program.sites
        @car_id = @reservation.car_id
        @start_time = params[:start_time]
        @end_time = params[:end_time]
        flash.now[:alert] = alert
        if params[:day_end].present?
          @day_end = params[:day_end].to_date
          render :edit_long, status: :unprocessable_entity
        else 
          render :edit, status: :unprocessable_entity
        end
        return
      end
    end
  end

  def send_reservation_updated_email
    authorize @reservation
    if params[:recurring] == "true"
      recurring = true
      note = "Email about updating this and following reservations was sent."
    else
      recurring = false
      note = "Email about updating this reservation was sent."
    end
    ReservationMailer.with(reservation: @reservation, user: current_user, recurring: recurring).car_reservation_updated(admin: false).deliver_now
    @email_log_entries = EmailLog.where(sent_from_model: "Reservation", record_id: @reservation.id).order(created_at: :desc)
    redirect_to reservation_path(@reservation), notice: note
  end

  def add_non_uofm_passengers
    @reservation = Reservation.find(params[:reservation_id])
    authorize @reservation
    respond_to do |format|
      if params[:recurring] == "true"
        recurring_reservation = RecurringReservation.new(@reservation)
        reservations_to_update = recurring_reservation.get_following
        Reservation.where(id: reservations_to_update).update_all(reservation_params.to_h)
      else
        @reservation.update(reservation_params)
      end
      @reservation = Reservation.find(params[:reservation_id])
      @passengers = @reservation.passengers
      @students = @reservation.program.students.order(:last_name) - @passengers
      @students.delete(@reservation.driver)
      @students.delete(@reservation.backup_driver)
      @passengers_managers = @reservation.passengers_managers
      @managers = @reservation.program.managers.to_a
      @managers << @reservation.program.instructor
      @managers = @managers - @passengers_managers
      @managers.delete(@reservation.driver_manager)
      format.turbo_stream { render :add_non_uofm_passenger }
    end
  end

  def add_drivers_later
    notice = "Reservation was created, but confirmation email was not sent."
    alert = "Send email manually after adding drivers. "
    if @reservation.recurring.present?
      if @reservation.recurring.present?
        recurring_reservation = RecurringReservation.new(@reservation)
        conflict_days_message = recurring_reservation.create_all
      end
        notice = "Recurring Reservations were created, but confirmation email was not sent."
        alert += conflict_days_message
    end
    redirect_to reservation_path(@reservation), notice: notice, alert: alert
  end

  def finish_reservation
    if @reservation.recurring.present?
      recurring_reservation = RecurringReservation.new(@reservation)
      conflict_days_message = recurring_reservation.create_all
      recurring = true
      notice = "Recurring reservations were created."
    else
      recurring = false
      notice = "Reservation was created."
    end
    ReservationMailer.with(reservation: @reservation, user: current_user, recurring: recurring).car_reservation_confirmation(conflict_days_message).deliver_now
    ReservationMailer.with(reservation: @reservation, user: current_user, recurring: recurring).car_reservation_created(conflict_days_message).deliver_now
    if recurring and conflict_days_message.present?
      alert = conflict_days_message
      if is_admin?
        alert += " drivers and passengers are notified. Please contact them in regards to the conflicts."
      else
        alert += " an email was sent to admins, and they will be in contact with you in regards to the conflicts."
      end
    end
    redirect_to reservation_path(@reservation), notice: notice, alert: alert
  end

  def update_passengers
    notice = ""
    alert = ""
    if params["recurring"] == "true"
      recurring = true
      notice = "Passengers list was updated for this and following recurring reservations."
    else
      recurring = false
      notice = "Passengers list was updated."
      if @reservation.recurring.present?
        recurring_reservation = RecurringReservation.new(@reservation)
        alert = recurring_reservation.remove_from_list
        if alert == ""
          notice += " Reservation was removed from the list of recurring reservations."
        end
      end
    end
    ReservationMailer.with(reservation: @reservation, user: current_user, recurring: recurring).car_reservation_update_passengers.deliver_now
    redirect_to reservation_path(@reservation), notice: notice, alert: alert
  end

  # add a reson to canceled reservations - modal form
  def cancel_reason
    @cancel_type = params[:cancel_type]
  end

  # soft cancel reservations - set canceled field to true, delete drivers and passengers, send email
  def cancel_reservation
    unless @reservation.vehicle_report.present?
      recurring = false
      create_cancel_emails
      if @reservation.passengers.present?
        @reservation.passengers.delete_all
      end
      if @reservation.passengers_managers.present?
        @reservation.passengers_managers.delete_all
      end
      reason_for_cancellation = params[:reason_for_cancellation]
      ReservationMailer.with(reservation: @reservation, user: current_user, recurring: recurring).car_reservation_cancel_admin(@cancel_passengers, @cancel_emails, reason_for_cancellation).deliver_now
      if @reservation.driver_id.present? || @reservation.driver_manager_id.present? 
        ReservationMailer.with(reservation: @reservation, user: current_user, recurring: recurring).car_reservation_cancel_driver(@cancel_passengers, @cancel_emails, reason_for_cancellation).deliver_now
      end
      begin
        @reservation.update(canceled: true, reason_for_cancellation: reason_for_cancellation, driver_id: nil, driver_manager_id: nil, updated_by: current_user.id)
        if is_admin?
          redirect_to reservations_url, notice: "Reservation was canceled."
          
        elsif is_manager?
          redirect_to welcome_pages_manager_url, notice: "Reservation was canceled."
          
        elsif is_student?
          redirect_to welcome_pages_student_url, notice: "Reservation was canceled."
          
        end
      rescue StandardError => e
        raise ActiveRecord::Rollback
        return false
      end
    else
      flash.now[:alert] = "The reservation has a vehicle report and can't be canceled."
      @email_log_entries = EmailLog.where(sent_from_model: "Reservation", record_id: @reservation.id).order(created_at: :desc)
      render :show, status: :unprocessable_entity
    end
  end

  def cancel_recurring_reservation
    recurring_reservation = RecurringReservation.new(@reservation)
    cancel_type = params[:cancel_type]
    reason_for_cancellation = params[:reason_for_cancellation]
    case cancel_type
    when "one"
      result = recurring_reservation.get_one_to_cancel
      cancel_message = ""
      recurring = false
    when "following"
      result = recurring_reservation.get_following_to_cancel
      recurring = true
      cancel_message = "This reservation and all the following recurring reservations "
    end
    result_with_vehicle_reports = result.select { |id| Reservation.find(id).vehicle_report.present?}
    if result_with_vehicle_reports.present?
      if cancel_type == "one"
        alert = "The reservation has a vehicle report and can't be canceled."
      else
        alert = "This and Following Reservations can't be canceled because vehicle reports exist for #{result_with_vehicle_reports}. To cancel this reservation click 'Cancel This Reservation' button."
      end
      flash.now[:alert] = alert
      @email_log_entries = EmailLog.where(sent_from_model: "Reservation", record_id: @reservation.id).order(created_at: :desc)
      render :show, status: :unprocessable_entity
    else
      create_cancel_emails
      ReservationMailer.with(reservation: @reservation, user: current_user, recurring: recurring).car_reservation_cancel_admin(@cancel_passengers, @cancel_emails, reason_for_cancellation, cancel_message, cancel_type).deliver_now
      if @reservation.driver_id.present? || @reservation.driver_manager_id.present? 
        ReservationMailer.with(reservation: @reservation, user: current_user, recurring: recurring).car_reservation_cancel_driver(@cancel_passengers, @cancel_emails, reason_for_cancellation, cancel_message, cancel_type).deliver_now
      end
      recurring_reservation.destroy_passengers(result)
      authorize @reservation
      if Reservation.where(id: result).update_all(canceled: true, reason_for_cancellation: reason_for_cancellation, driver_id: nil, driver_manager_id: nil, updated_by: current_user.id, prev: nil, next: nil, updated_at: Time.now)
        if is_admin?
          redirect_to reservations_url, notice: "Selected Reservation(s) were canceled."
        elsif is_manager?
          redirect_to welcome_pages_manager_url, notice: "Selected Reservation(s) were canceled."
        elsif is_student?
          redirect_to welcome_pages_student_url, notice: "Selected Reservation(s) were canceled."
        end
      else
        flash.now[:alert] = "Error canceling reservations"
        @email_log_entries = EmailLog.where(sent_from_model: "Reservation", record_id: @reservation.id).order(created_at: :desc)
        render :show, status: :unprocessable_entity
      end
    end
  end

  def approve_all_recurring
    recurring_reservation = RecurringReservation.new(@reservation)
    result = recurring_reservation.get_all_reservations
    note = ""
    result.each do |id|
      if Reservation.find(id).update(approved: true)
        ReservationMailer.with(reservation: Reservation.find(id), user: current_user).car_reservation_approved.deliver_now
      else
        note += "Reservation #{id} was not approved. "
      end
    end
    if note == ""
      note = "All recurring reservations were approved."
      redirect_to reservation_path(@reservation), notice: note
    else
      redirect_to reservation_path(@reservation), alert: note
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.

    def set_calendar_reservations
      start_date = params.fetch(:start_date, Date.today).to_date
      if session[:unit_ids].count == 1
        @unit_id = session[:unit_ids][0]
        @reservations = Reservation.where(program: Program.where(unit_id: @unit_id)).where("start_time BETWEEN ? and ? OR end_time BETWEEN ? and ?", start_date.beginning_of_month.beginning_of_week, start_date.end_of_month.end_of_week, start_date.beginning_of_month.beginning_of_week, start_date.end_of_month.end_of_week)
      elsif params[:unit_id].present?
        @unit_id = params[:unit_id]
        @reservations = Reservation.where(program: Program.where(unit_id: @unit_id)).where("start_time BETWEEN ? and ? OR end_time BETWEEN ? and ?", start_date.beginning_of_month.beginning_of_week, start_date.end_of_month.end_of_week, start_date.beginning_of_month.beginning_of_week, start_date.end_of_month.end_of_week)
      else
        @reservations = Reservation.where("start_time BETWEEN ? and ? OR end_time BETWEEN ? and ?", start_date.beginning_of_month.beginning_of_week, start_date.end_of_month.end_of_week, start_date.beginning_of_month.beginning_of_week, start_date.end_of_month.end_of_week)
      end
    end
    
    def set_reservation
      @reservation = Reservation.unscoped.find(params[:id])
      authorize @reservation
    end

    def set_terms_and_units
      @terms = Term.current_and_future
      @units = Unit.where(id: session[:unit_ids]).order(:name)
    end

    def set_programs
      @programs = Program.where(unit_id: session[:unit_ids]).order(:title)
    end

    def set_cars
      @cars = Car.available.data(params[:unit_id]).order(:car_number)
    end

    def set_number_of_seats
      @number_of_seats = 1..Car.available.maximum(:number_of_seats)
    end

    def get_data_for_program(program)
      @unit_id = program.unit_id
      @term_id = program.term.id
      @sites = program.sites.order(:title)
      @cars = @cars.where(unit_id: @unit_id).order(:car_number)
      @min_date = default_reservation_for_students(@unit_id)
      @max_date = max_day_for_reservation(@unit_id)
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

    def list_of_drivers(reservation)
      drivers = reservation.program.students.eligible_drivers.map { |d| [d.display_name, d.id.to_s + "-student"] }
      if is_admin?
        manager_drivers = reservation.program.managers.eligible_drivers.map { |d| [d.display_name + " (manager)", d.id.to_s + "-manager"] }
        if reservation.program.instructor.can_reserve_car?
          manager_drivers << [reservation.program.instructor.display_name + " (instructor)", reservation.program.instructor_id.to_s + "-manager"]
        end
        drivers.concat manager_drivers
      end
      return drivers
    end

    def reservation_driver(reservation)
      driver = []
      if reservation.driver_id.present?
        driver = [reservation.driver.display_name, reservation.driver_id.to_s + "-student"]
      elsif reservation.driver_manager_id.present?
        driver = [reservation.driver_manager.display_name, reservation.driver_manager_id.to_s + "-manager"]
      else
        nil
      end
    end

    def create_cancel_emails
      students = @reservation.passengers
      managers = @reservation.passengers_managers
      @cancel_passengers = []
      @cancel_emails = []
      if students.present? || managers.present?
        students.each do |s|
          @cancel_passengers << s.name
          @cancel_emails << email_address(s)
        end
        managers.each do |m|
          @cancel_passengers << m.name
          @cancel_emails << email_address(m)
        end
      else
        @cancel_passengers = ["No passengers"]
      end
      if @reservation.program.non_uofm_passengers && @reservation.non_uofm_passengers.present?
        @cancel_passengers << "Non UofM Passengers: " + @reservation.non_uofm_passengers
      end
    end

    # Only allow a list of trusted parameters through.
    def reservation_params
      params.require(:reservation).permit(:status, :start_time, :end_time, :recurring, :driver_id, :driver_manager_id, :driver_phone, :backup_driver_id, :backup_driver_phone, 
      :number_of_people_on_trip, :program_id, :site_id, :car_id, :reserved_by, :approved, :non_uofm_passengers, :number_of_non_uofm_passengers, :until_date, :updated_by, :canceled, :reason_for_cancellation)
    end
end
