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
    @passengers = @reservation.passengers
    @email_log_entries = EmailLog.where(sent_from_model: "Reservation", record_id: @reservation.id).order(created_at: :desc)
  end

  # GET /reservations/new
  def new
    @reservation = Reservation.new
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
    end
    if params[:end_time].present?
      @end_time = params[:end_time]
    end
    if ((@end_time.to_datetime - @start_time.to_datetime) * 24 * 60).to_i > 30
      @reserv_begin = @start_time.to_datetime
      @reserv_end = @end_time.to_datetime
      range = @reserv_begin..@reserv_end
      @cars = available_cars(@cars, range)
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
      recurring_reservation =  RecurringReservation.new(@reservation)
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
      @reservation.attributes = reservation_params
      @reservation.car_id = params[:car_id]
      @reservation.start_time = params[:start_time].to_datetime - 15.minute
      @reservation.end_time = params[:end_time].to_datetime + 15.minute
      @reservation.number_of_people_on_trip = params[:number_of_people_on_trip]

      respond_to do |format|
        if @reservation.update(reservation_params)
          format.html { redirect_to reservation_url(@reservation), notice: "Reservation was successfully updated." }
          format.json { render :show, status: :ok, location: @reservation }
        else
          @programs = Program.where(unit_id: current_user.unit_ids).order(:title, :catalog_number, :class_section)
          @number_of_seats = 1..Car.available.maximum(:number_of_seats)
          @number_of_people_on_trip = Reservation.find(params[:id]).number_of_people_on_trip
          @day_start = params[:day_start].to_date
          @unit_id = params[:reservation][:unit_id]
          @cars = Car.available.where(unit_id: @unit_id).order(:car_number)
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
    drivers_emails = reservation_drivers_emails
    if params[:recurring] == "true"
      recurring_reservation =  RecurringReservation.new(@reservation)
      recurring = true
    end
    if @reservation.driver_manager.present? && params[:reservation][:driver_id].present?
      if params[:recurring] == "true"
        Reservation.where(id: reservations_to_update).update_all(driver_manager: nil)
      else
        @reservation.update(driver_manager: nil)
      end
    end
    # check if a new driver is a passenger
    note = ""
    if params[:reservation][:driver_id].present? && @reservation.passengers.include?(Student.find(params[:reservation][:driver_id]))
      if params[:recurring] == "true"
        recurring_reservation.remove_passenger_following_reservations(Student.find(params[:reservation][:driver_id]))
      else
        @reservation.passengers.delete(Student.find(params[:reservation][:driver_id]))
      end
      note += " Driver was removed from passengers list."
    end
    if params[:reservation][:backup_driver_id].present? && @reservation.passengers.include?(Student.find(params[:reservation][:backup_driver_id]))
      if params[:recurring] == "true"
        recurring_reservation.remove_passenger_following_reservations(Student.find(params[:reservation][:backup_driver_id]))
      else
        @reservation.passengers.delete(Student.find(params[:reservation][:backup_driver_id]))
      end
      note += " Backup Driver was removed from passengers list."
    end

    if params[:recurring] == "true"
      notice = recurring_reservation.update_drivers(reservation_params.to_h) + note
    else
      if @reservation.update(reservation_params)
        notice = "Drivers were updated." + note
      else
        success = false
      end
    end
    if success
      if params[:edit] == "true"
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
      @drivers = @reservation.program.students.eligible_drivers
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
    params[:reservation][:non_uofm_passengers].present?
    respond_to do |format|
      if @reservation.update(reservation_params)
        @passengers = @reservation.passengers
        @students = @reservation.program.students.order(:last_name) - @passengers
        @students.delete(@reservation.driver)
        @students.delete(@reservation.backup_driver)
        format.turbo_stream { render :add_non_uofm_passenger }
      end
    end
  end

  def add_drivers
    @drivers = @reservation.program.students.eligible_drivers
    @passengers = @reservation.passengers
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
    end
    ReservationMailer.with(reservation: @reservation).car_reservation_confirmation(current_user).deliver_now
    ReservationMailer.with(reservation: @reservation).car_reservation_created(current_user).deliver_now
    redirect_to reservation_path(@reservation)
  end

  def update_passengers
    ReservationMailer.with(reservation: @reservation).car_reservation_update_passengers(current_user).deliver_now
    redirect_to reservation_path(@reservation), notice: "Passengers list was updated"
  end

  # DELETE /reservations/1 or /reservations/1.json
  def destroy
    unless @reservation.approved
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
      cancel_type = params[:cancel_type]
      recurring_reservation =  RecurringReservation.new(@reservation)
      case cancel_type
      when "one"
        result = recurring_reservation.get_one
      when "following"
        result = recurring_reservation.get_following
      when "all"
        result = recurring_reservation.get_all_reservations
      end
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
    recurring_reservation =  RecurringReservation.new(@reservation)
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
      drivers_emails = []
      if @reservation.driver.present?
        drivers_emails << email_address(@reservation.driver)
      end
      if @reservation.backup_driver.present?
        drivers_emails << email_address(@reservation.backup_driver)
      end
      if @reservation.driver_manager.present?
        drivers_emails << email_address(@reservation.driver_manager)
      end
      return drivers_emails
    end

    # Only allow a list of trusted parameters through.
    def reservation_params
      params.require(:reservation).permit(:status, :start_time, :end_time, :recurring, :driver_id, :driver_manager_id, :driver_phone, :backup_driver_id, :backup_driver_phone, 
      :number_of_people_on_trip, :program_id, :site_id, :car_id, :reserved_by, :approved, :non_uofm_passengers, :number_of_non_uofm_passengers, :until_date)
    end
end
