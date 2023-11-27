class ReservationsController < ApplicationController
  before_action :auth_user
  before_action :set_reservation, only: %i[ show edit update destroy add_drivers add_passengers remove_passenger 
    finish_reservation update_passengers send_reservation_updated_email cancel_recurring_reservation add_drivers_later approve_all_recurring edit_long add_edit_drivers]
  before_action :set_terms_and_units
  before_action :set_programs
  before_action :set_cars, only: %i[ new new_long get_available_cars get_available_cars_long ]
  before_action :set_number_of_seats, only: %i[ new new_long create edit edit_long ]

  # GET /reservations or /reservations.json
  def index
    if current_user.unit_ids.count == 1
      @unit_id = current_user.unit_ids[0]
      @reservations = Reservation.where(program: Program.where(unit_id: @unit_id))
    elsif params[:unit_id].present?
      @unit_id = params[:unit_id]
      @reservations = Reservation.where(program: Program.where(unit_id: @unit_id))
    else
      @reservations = Reservation.all
    end
    authorize @reservations
  end

  def week_calendar
    @no_car = false
    session[:return_to] = request.referer
    if current_user.unit_ids.count == 1
      @unit_id = current_user.unit_ids[0]
      @reservations = Reservation.where(program: Program.where(unit_id: @unit_id))
    elsif params[:unit_id].present?
      @unit_id = params[:unit_id]
      @reservations = Reservation.where(program: Program.where(unit_id: @unit_id))
    else
      authorize Reservation
      redirect_back_or_default("You must select a unit first.", reservations_url, true)
      return
    end
    @hour_begin = UnitPreference.find_by(name: "reservation_time_begin", unit_id: @unit_id).value.split(":").first.to_i - 1
    @hour_end = UnitPreference.find_by(name: "reservation_time_end", unit_id: @unit_id).value.split(":").first.to_i + 12
    authorize @reservations
    @cars = Car.available.where(unit_id: @unit_id).order(:car_number)
    @date_range = Date.today.beginning_of_week..Date.today.end_of_week
    @dates = @date_range.to_a
  end

  def day_reservations
    @reservations = Reservation.where(program: Program.where(unit_id: current_user.unit_ids))
    @day = params[:date].to_date
    @day_reservations = @reservations.where("(start_time BETWEEN ? AND ?) OR (start_time < ? AND end_time > ?)", @day.beginning_of_day, @day.end_of_day, @day.end_of_day, @day.beginning_of_day).order(:start_time)
    authorize @day_reservations
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
    @term_id = Term.current[0].id
    authorize @reservation
    if is_student?(current_user)
      @program = Student.find(params[:student_id]).program
      get_data_for_program(@program)
    elsif is_manager?(current_user)
      @program = Program.find(params[:program_id])
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
    end
    if is_admin?(current_user)
      @sites = []
    end
    @until_date = Term.current.pluck(:classes_end_date).min
    @reservation.start_time = @day_start
  end

  def new_long
    new
    if params[:day_end].present?
      @day_end = params[:day_end].to_date
    else
      @day_end = @day_start
    end
    @reservation.end_time = @day_end
  end

  # GET /reservations/1/edit
  def edit
    @day_start = @reservation.start_time.to_date
    @unit_id = @reservation.program.unit.id
    @term_id = @reservation.program.term.id
    @car_id = @reservation.car_id
    @start_time = (@reservation.start_time + 15.minute).to_s
    @end_time = (@reservation.end_time - 15.minute).to_s
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
      @until_date = Term.current.pluck(:classes_end_date).min
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
      day_start_beginning = unit_begining_of_day(@day_start, @unit_id) - 15.minute
      day_start_finish = unit_end_of_day(@day_start, @unit_id) + 15.minute

      day_end_begining = unit_begining_of_day(@day_end, @unit_id) - 15.minute
      day_end_finish = unit_end_of_day(@day_end, @unit_id) + 15.minute

      long_reservations = cars_reservations.where("start_time < ? AND end_time > ?", day_start_finish, day_end_begining).pluck(:car_id)
      between_reservations = cars_reservations.where(start_time: (day_start_beginning + 1.day).., end_time: ..(day_end_finish - 1.day)).pluck(:car_id)
      day_start_reservations = cars_reservations.where(start_time: day_start_beginning..day_start_finish, end_time: day_start_finish - 30.minute..day_start_finish).pluck(:car_id)
      day_end_reservations = cars_reservations.where(start_time: day_end_begining..day_end_begining + 30.minute, end_time: day_end_begining..day_end_finish).pluck(:car_id)
      exclude_cars = (between_reservations + day_start_reservations + day_end_reservations + long_reservations).uniq
      @cars = @cars.where.not(id: exclude_cars)
    end
    if params[:until_date].present?
      @until_date = params[:until_date]
    else
      @until_date = Term.current.pluck(:classes_end_date).min
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
    @start_time = @day_start + Time.parse(params[:start_time]).seconds_since_midnight.seconds
    @end_time = @day_start + Time.parse(params[:end_time]).seconds_since_midnight.seconds
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
    if @reservation.save
      @students = @reservation.program.students 
      redirect_to add_drivers_path(@reservation), notice: "Reservation was successfully created. Please add drivers."
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
  end

  def edit_change_day
    if params[:unit_id].present?
      @unit_id = params[:unit_id]
    end
    if params[:day_start].present?
      @day_start = params[:day_start].to_date
      @start_time = @day_start + Time.parse(params[:start_time]).seconds_since_midnight.seconds
      @end_time = @day_start + Time.parse(params[:end_time]).seconds_since_midnight.seconds
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
      @start_time = @day_start + Time.parse(params[:start_time]).seconds_since_midnight.seconds
    end
    if params[:day_end].present?
      @day_end = params[:day_end].to_date
      @end_time = @day_end + Time.parse(params[:end_time]).seconds_since_midnight.seconds
    end
    # @cars = Car.available.where(unit_id: @unit_id).order(:car_number)
    authorize Reservation
  end

  # PATCH/PUT /reservations/1 or /reservations/1.json
  def update
    if params[:reservation][:approved].present?
      if @reservation.update(reservation_params)
        ReservationMailer.with(reservation: @reservation).car_reservation_approved(current_user).deliver_now unless @reservation.approved == false
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
      result = recurring_reservation.get_following
      update_params = {}
      update_params["site_id"] = reservation_params[:site_id]
      update_params["car_id"] = params[:car_id]
      update_params["number_of_people_on_trip"] = params[:number_of_people_on_trip]
      start_time = params[:start_time].to_datetime - 15.minute
      end_time = params[:end_time].to_datetime + 15.minute
      note = ""
      result.each do |id|
        reservation = Reservation.find(id)
        day_start = reservation.start_time.beginning_of_day
        day_end = reservation.end_time.beginning_of_day
        update_params["start_time"] = day_start + Time.parse(start_time.strftime("%I:%M%p")).seconds_since_midnight.seconds
        update_params["end_time"] = day_end + Time.parse(end_time.strftime("%I:%M%p")).seconds_since_midnight.seconds
        unless reservation.update(update_params)
          note += "Reservation #{id} was not updated: " + reservation.errors.full_messages.join(',') + ". "
        end
      end
      if note == ""
        note = "This and all following recurring reservations were updated."
        redirect_to reservation_path(@reservation), notice: note
      else
        redirect_to reservation_path(@reservation), alert: note
      end
    else
      notice = ""
      if @reservation.recurring.present?
        recurring_reservation = RecurringReservation.new(@reservation)
        note = recurring_reservation.remove_from_list
        if note == ""
          notice = " Reservation was removed from the list of recurring reservations."
        else
          redirect_to reservation_path(@reservation), notice: "Reservation was not updated." + note
          return
        end
      end
      @reservation.attributes = reservation_params
      @reservation.car_id = params[:car_id]
      @reservation.start_time = params[:start_time].to_datetime - 15.minute
      @reservation.end_time = params[:end_time].to_datetime + 15.minute
      @reservation.number_of_people_on_trip = params[:number_of_people_on_trip]

      respond_to do |format|
        if @reservation.update(reservation_params)
          format.html { redirect_to reservation_url(@reservation), notice: "Reservation was successfully updated." + notice }
          format.json { render :show, status: :ok, location: @reservation }
        else
          @programs = Program.where(unit_id: current_user.unit_ids).order(:title, :catalog_number, :class_section)
          @number_of_seats = 1..Car.available.maximum(:number_of_seats)
          @number_of_people_on_trip = Reservation.find(params[:id]).number_of_people_on_trip
          @day_start = params[:day_start].to_date
          @unit_id = params[:unit_id]
          @cars = Car.available.where(unit_id: @unit_id).order(:car_number)
          @sites = @reservation.program.sites
          @car_id = @reservation.car_id
          @start_time = params[:start_time]
          @end_time = params[:end_time]
          @students = Student.all
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @reservation.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def add_edit_drivers
    success = true
    recurring = false
    note = ""
    drivers_emails = reservation_drivers_emails
    @reservation.attributes = reservation_params
    if params[:recurring] == "true"
      recurring_reservation = RecurringReservation.new(@reservation)
      recurring = true
    end
    # check if a new driver is a student or a manager
    driver_param = params[:driver_id].split("-")
    driver_type = driver_param[1]
    driver_id = driver_param[0].to_i
    if driver_type == "student"
      @reservation.driver_id = driver_id
      @reservation.driver_manager_id = nil
    elsif driver_type == "manager"
      @reservation.driver_manager_id = driver_id
      @reservation.driver_id = nil
    end
    if params[:edit] == "true"
      # check if a new driver is a passenger
      note = check_if_driver_is_passenger(@reservation, driver_type, "Driver", driver_id, recurring)
      # check if a new backup driver is a passenger
      if params[:reservation][:backup_driver_id].present? 
        note += check_if_driver_is_passenger(@reservation, "student", "Backup Driver", params[:reservation][:backup_driver_id], recurring)
      end
    end
    if params[:recurring] == "true"
      list_of_params = reservation_params.to_h
      list_of_params["driver_id"] = params[:driver_id]
      notice = recurring_reservation.update_drivers(list_of_params) + note
    else
      if @reservation.update(reservation_params)
        notice = "Drivers were updated." + note
      else
        success = false
      end
    end
    if success
      if params[:edit] == "true"
        if params[:recurring].empty? && @reservation.recurring.present?
          recurring_reservation = RecurringReservation.new(@reservation)
          result = recurring_reservation.remove_from_list
          if result == ""
            note += " Reservation was removed from the list of recurring reservations."
          else
            redirect_to reservation_path(@reservation), alert: note + result
            return
          end
        end
        @reservation = Reservation.find(params[:id])
        drivers_emails_new = reservation_drivers_emails
        if drivers_emails == drivers_emails_new
          notice = "Drivers were not changed"
        else
          drivers_emails << drivers_emails_new
          drivers_emails = drivers_emails.flatten.uniq
          ReservationMailer.car_reservation_drivers_edited(@reservation, drivers_emails, current_user, recurring).deliver_now
          notice += " Old Drivers were removed from the trip."
        end
        redirect_to reservation_path(@reservation), notice: notice
        return
      else
        redirect_to add_passengers_path(@reservation)
        return
      end
    else
      @backup_drivers = @reservation.program.students.eligible_drivers
      @all_drivers = list_of_drivers(@reservation)
      @driver = reservation_driver(@reservation)
      render :add_drivers, status: :unprocessable_entity
      return
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
    ReservationMailer.with(reservation: @reservation).car_reservation_updated(current_user, recurring).deliver_now
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

  def add_drivers
    @backup_drivers = @reservation.program.students.eligible_drivers
    @all_drivers = list_of_drivers(@reservation)
    @passengers = @reservation.passengers
    @driver = reservation_driver(@reservation)
    unless is_admin?(current_user)
      if is_student?(current_user)
        driver = Student.find_by(program_id: @reservation.program_id, uniqname: current_user.uniqname)
        @reservation.update(driver_id: driver.id)
      elsif is_manager?(current_user)
        driver_manager = Manager.find_by(uniqname: current_user.uniqname)
        @reservation.update(driver_manager_id: driver_manager.id)
      end
    end
  end

  def add_drivers_later
    if @reservation.recurring.present?
      if @reservation.recurring.present?
        recurring_reservation = RecurringReservation.new(@reservation)
        recurring_reservation.create_all
      end
      redirect_to reservation_path(@reservation)
      return
    end
    redirect_to reservation_path(@reservation)
  end

  def finish_reservation
    if @reservation.recurring.present?
      recurring_reservation = RecurringReservation.new(@reservation)
      recurring_reservation.create_all
      recurring = true
    else
      recurring = false
    end
    ReservationMailer.with(reservation: @reservation).car_reservation_confirmation(current_user, recurring).deliver_now
    ReservationMailer.with(reservation: @reservation).car_reservation_created(current_user, recurring).deliver_now
    redirect_to reservation_path(@reservation)
  end

  def update_passengers
    if params["recurring"] == "true"
      recurring = true
      notice = "Passengers list was updated for this and following recurring reservations."
    else
      recurring = false
      notice = "Passengers list was updated."
      if @reservation.recurring.present?
        recurring_reservation = RecurringReservation.new(@reservation)
        note = recurring_reservation.remove_from_list
        if note == ""
          notice += " Reservation was removed from the list of recurring reservations."
        else
          redirect_to reservation_path(@reservation), alert: notice + note
          return
        end
      end
    end
    ReservationMailer.with(reservation: @reservation).car_reservation_update_passengers(current_user, recurring).deliver_now
    redirect_to reservation_path(@reservation), notice: notice
  end

  # DELETE /reservations/1 or /reservations/1.json
  def destroy
    unless @reservation.approved
      recurring = false
      create_cancel_emails
      if @reservation.passengers.present?
        @reservation.passengers.delete_all
      end
      if @reservation.passengers_managers.present?
        @reservation.passengers_managers.delete_all
      end
      ReservationMailer.car_reservation_cancel_admin(@reservation, @cancel_passengers, @cancel_emails, current_user, recurring).deliver_now
      if @reservation.driver_id.present? || @reservation.driver_manager_id.present? 
        ReservationMailer.car_reservation_cancel_driver(@reservation, @cancel_passengers, @cancel_emails, current_user, recurring).deliver_now
      end
      respond_to do |format|
        if @reservation.destroy
          if is_admin?(current_user)
            format.html { redirect_to reservations_url, notice: "Reservation was canceled." }
            format.json { head :no_content }
          elsif is_manager?(current_user)
            format.html { redirect_to welcome_pages_manager_url, notice: "Reservation was canceled." }
            format.json { head :no_content }
          elsif is_student?(current_user)
            format.html { redirect_to welcome_pages_student_url, notice: "Reservation was canceled." }
            format.json { head :no_content }
          end
        else
          format.html { render :show, status: :unprocessable_entity }
          format.json { render json: @reservation.errors, status: :unprocessable_entity }
        end
      end
    else
      flash.now[:alert] = 'The reservation is approved. To cancel, please contact your administrator'
      render turbo_stream: turbo_stream.update("flash", partial: "layouts/notification")
    end
  end

  def cancel_recurring_reservation
    unless @reservation.approved
      create_cancel_emails
      cancel_type = params[:cancel_type]
      cancel_message = ""
      recurring_reservation = RecurringReservation.new(@reservation)
      case cancel_type
      when "one"
        result = recurring_reservation.get_one_to_delete
        recurring = false
      when "following"
        result = recurring_reservation.get_following_to_delete
        recurring = true
        cancel_message = "This reservation and all the following recurring reservations "
      when "all"
        result = recurring_reservation.get_all_reservations
        recurring = true
        cancel_message = "Recurring Reservations starting on #{recurring_reservation.start_on} and "
      end
      ReservationMailer.car_reservation_cancel_admin(@reservation, @cancel_passengers, @cancel_emails, current_user, recurring, cancel_message).deliver_now
      if @reservation.driver_id.present? || @reservation.driver_manager_id.present? 
        ReservationMailer.car_reservation_cancel_driver(@reservation, @cancel_passengers, @cancel_emails, current_user, recurring, cancel_message).deliver_now
      end
      recurring_reservation.destroy_passengers(result)
      authorize @reservation
      respond_to do |format|
        if Reservation.where(id: result).destroy_all
          if is_admin?(current_user)
            format.turbo_stream { redirect_to reservations_url, notice: "Selected Reservation(s) were canceled." }
          elsif is_student?(current_user)
            format.turbo_stream { redirect_to welcome_pages_student_url, notice: "Selected Reservation(s) were canceled." }
          elsif is_manager?(current_user)
            format.turbo_stream { redirect_to welcome_pages_manager_url, notice: "Selected Reservation(s) were canceled." }
          end
        else
          render :show, status: :unprocessable_entity
        end
      end
    else
      flash.now[:alert] = 'The reservation is approved. To cancel, please contact your administrator'
      render turbo_stream: turbo_stream.update("flash", partial: "layouts/notification")
    end
  end

  def approve_all_recurring
    recurring_reservation = RecurringReservation.new(@reservation)
    result = recurring_reservation.get_all_reservations
    note = ""
    result.each do |id|
      if Reservation.find(id).update(approved: true)
        ReservationMailer.with(reservation: Reservation.find(id)).car_reservation_approved(current_user).deliver_now
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
    def set_reservation
      @reservation = Reservation.find(params[:id])
      authorize @reservation
    end

    def set_terms_and_units
      @terms = Term.current_and_future
      @units = Unit.where(id: current_user.unit_ids).order(:name)
    end

    def set_programs
      @programs = Program.where(unit_id: current_user.unit_ids).order(:title)
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
      @max_date = max_day_for_reservation(program)
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
      if is_admin?(current_user)
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

    def check_if_driver_is_passenger(reservation, driver_type, field, driver_id, recurring)
      # check if a new driver is a passenger
      note = ""
      if driver_type == "student"
        student = Student.find(driver_id)
        if @reservation.passengers.include?(student)
          if recurring
            recurring_reservation = RecurringReservation.new(reservation)
            recurring_reservation.remove_passenger_following_reservations(student)
          else
            reservation.passengers.delete(student)
          end
          note = " " + field + " was removed from passengers list."
        end
      else
        manager = Manager.find(driver_id)
        if @reservation.passengers_managers.include?(manager)
          if recurring
            recurring_reservation = RecurringReservation.new(reservation)
            recurring_reservation.remove_passenger_following_reservations(manager)
          else
            reservation.passengers_managers.delete(manager)
          end
          note = " " + field + " was removed from passengers list."
        end
      end
      return note
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
      :number_of_people_on_trip, :program_id, :site_id, :car_id, :reserved_by, :approved, :non_uofm_passengers, :number_of_non_uofm_passengers, :until_date)
    end
end
