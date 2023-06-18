class ReservationsController < ApplicationController
  before_action :auth_user
  before_action :set_reservation, only: %i[ show edit update destroy add_drivers add_passengers remove_passenger ]
  before_action :set_terms_and_units
  before_action :set_programs
  before_action :set_cars, only: %i[ new get_available_cars ]
  before_action :set_number_of_seats, only: %i[ new create edit ]

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

  # GET /reservations/1 or /reservations/1.json
  def show
    @passengers = @reservation.passengers
  end

  # GET /reservations/new
  def new
    if is_student?(current_user)
      @program = Student.find(params[:student_id]).program
      @unit_id = @program.unit_id
      @term_id = @program.term.id
      @sites = @program.sites
      @cars = @cars.where(unit_id: @unit_id)
      @min_date = default_reservation_for_students
    elsif params[:unit_id].present?
      @unit_id = params[:unit_id]
      @min_date =  DateTime.now
    else
      redirect_to reservations_path, notice: "You must select a unit first."
    end
    if params[:day_start].present?
      @day_start = params[:day_start].to_date
    else
      @day_start = default_reservation_for_students
    end
    if params[:term_id].present?
      @term_id = params[:term_id]
    end
    @students = []
    if is_admin?(current_user)
      @sites = []
    end
    @reservation = Reservation.new
    @reservation.start_time = @day_start
    authorize @reservation
  end

  # GET /reservations/1/edit
  def edit
    @sites = @reservation.program.sites
    @day_start = @reservation.start_time.to_date
    @unit_id = @reservation.program.unit.id
    @term_id = @reservation.program.term.id
    @car_id = @reservation.car_id
    @start_time = @reservation.start_time.to_s
    @end_time = @reservation.end_time.to_s
    @number_of_people_on_trip = @reservation.number_of_people_on_trip
    @cars = list_of_available_cars(@unit_id, @day_start, @number_of_people_on_trip, @start_time, @end_time)

  end

  def get_available_cars
    if params[:unit_id].present?
      @unit_id = params[:unit_id]
    end
    if params[:day_start].present?
      @day_start = params[:day_start].to_date
    end
    if params[:number].present?
      @cars = @cars.where("number_of_seats >= ?", params[:number])
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

  # POST /reservations or /reservations.json
  def create
    @reservation = Reservation.new(reservation_params)
    if params[:car_id].present?
      @reservation.car_id = params[:car_id]
      @car_id = params[:car_id]
    end
    @reservation.start_time = (params[:start_time]).to_datetime
    @reservation.end_time = (params[:end_time]).to_datetime
    @reservation.number_of_people_on_trip = params[:number_of_people_on_trip]
    @reservation.reserved_by = current_user.id
    authorize @reservation
    if @reservation.save
      @students = @reservation.program.students 
      redirect_to add_drivers_path(@reservation), notice: "Reservation was successfully created. Please add drivers."
    else
      @program = Program.find(params[:reservation][:program_id])
      @term_id = params[:term_id]
      @sites = @program.sites
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

  # PATCH/PUT /reservations/1 or /reservations/1.json
  def update
    if params[:reservation][:driver_id].present?
      if @reservation.update(reservation_params)
        redirect_to add_passengers_path(@reservation)
        return
      else
        flash.now[:alert] = "error"
        @drivers = @reservation.program.students.eligible_drivers
        format.turbo_stream { render :add_drivers, status: :unprocessable_entity }
        return
      end
    end
    if params[:reservation][:student_id].present?
      @reservation.passengers << Student.find(params[:reservation][:student_id])
      @students = @reservation.program.students - @reservation.passengers
      redirect_to add_passengers_path(@reservation)
      return
    end
    if params[:reservation][:non_uofm_passengers].present?
      @reservation.update(non_uofm_passengers: params[:reservation][:non_uofm_passengers])
      redirect_to add_passengers_path(@reservation)
      return
    end
    @reservation.attributes = reservation_params
    @reservation.car_id = params[:car_id]
    @reservation.start_time = (params[:start_time]).to_datetime
    @reservation.end_time = (params[:end_time]).to_datetime
    @reservation.number_of_people_on_trip = params[:number_of_people_on_trip]
    respond_to do |format|
      if @reservation.update(reservation_params)
        format.html { redirect_to reservation_url(@reservation), notice: "Reservation was successfully updated." }
        format.json { render :show, status: :ok, location: @reservation }
      else
        @programs = Program.where(unit_id: current_user.unit)
        @students = Student.all
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @reservation.errors, status: :unprocessable_entity }
      end
    end
  end

  def add_drivers
    @drivers = @reservation.program.students.eligible_drivers
    @passengers = @reservation.passengers
    unless is_admin?(current_user)
      driver = Student.find_by(program_id: @reservation.program_id, uniqname: current_user.uniqname)
      @reservation.update(driver_id: driver.id)
    end
  end

  def add_passengers
    @passengers = @reservation.passengers
    @students = @reservation.program.students - @passengers
    @students.delete(@reservation.driver)
    @students.delete(@reservation.backup_driver)
  end

  def remove_passenger
    @reservation.passengers.delete(Student.find(params[:student_id]))
    add_passengers
  end

  # DELETE /reservations/1 or /reservations/1.json
  def destroy
    @reservation.destroy

    respond_to do |format|
      format.html { redirect_to reservations_url, notice: "Reservation was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_reservation
      @reservation = Reservation.find(params[:id])
      authorize @reservation
    end

    def set_terms_and_units
      @terms = Term.sorted
      @units = Unit.where(id: current_user.unit_ids).order(:name)
    end

    def set_programs
      @programs = Program.where(unit_id: current_user.unit_ids)
    end

    def set_cars
      @cars = Car.available.data(params[:unit_id]).order(:car_number)
    end

    def set_number_of_seats
      @number_of_seats = 1..Car.available.maximum(:number_of_seats)
    end

    # Only allow a list of trusted parameters through.
    def reservation_params
      params.require(:reservation).permit(:status, :start_time, :end_time, :recurring, :driver_id, :driver_phone, :backup_driver_id, :backup_driver_phone, 
      :number_of_people_on_trip, :program_id, :site_id, :car_id, :reserved_by)
    end
end
