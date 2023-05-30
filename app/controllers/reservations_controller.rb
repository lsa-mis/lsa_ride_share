class ReservationsController < ApplicationController
  before_action :auth_user
  before_action :set_reservation, only: %i[ show edit update destroy add_passengers remove_passenger ]
  before_action :set_terms_and_units
  before_action :set_programs

  # GET /reservations or /reservations.json
  def index
    @reservations = Reservation.all
    authorize @reservations
  end

  # GET /reservations/1 or /reservations/1.json
  def show
  end

  # GET /reservations/new
  def new
    if params[:day_start].present?
      @day_start = params[:day_start].to_date
    else
      @day_start = Date.today
    end
    @programs = Program.where(unit_id: current_user.unit_ids)
    @students = []
    @sites = []
    @cars = Car.all
    @number_of_seats = 1..Car.maximum(:number_of_seats)
    @reservation = Reservation.new
    @reservation.start_time = @day_start 
    authorize @reservation
  end

  # GET /reservations/1/edit
  def edit
  end

  def get_available_cars
    if params[:day_start].present?
      @day_start = params[:day_start].to_date
    else
      @day_start = Date.today
    end
    if params[:number].present?
      @cars = Car.where("number_of_seats >= ?", params[:number])
    else
      @cars = Car.all
    end
    if params[:time_start].present?
      @time_start = params[:time_start]
    end
    if params[:time_end].present?
      @time_end = params[:time_end]
    end
    unless params[:time_start] == params[:time_end]
      @reserv_begin = Time.zone.parse(params[:day_start] + " " + params[:time_start]).to_datetime
      @reserv_end = Time.zone.parse(params[:day_start] + " " + params[:time_end]).to_datetime
      range = @reserv_begin..@reserv_end
      @cars = available_cars(@cars, range)
    end
    authorize Reservation
    # turbo_stream.update "available_cars", partial: "available_cars"
    # render json: @cars
  end

  # POST /reservations or /reservations.json
  def create
    @reservation = Reservation.new
    @reservation.start_time = Time.zone.parse(params[:day_start] + " " + params[:time_start]).to_datetime
    @reservation.end_time = Time.zone.parse(params[:day_start] + " " + params[:time_end]).to_datetime
    @reservation.program_id = params[:program_id]
    @reservation.site_id = params[:site_id]
    @reservation.car_id = params[:reservation][:car_id]
    @reservation.number_of_people_on_trip = params[:number_of_people_on_trip]
    @reservation.reserved_by = current_user.id
    authorize @reservation
    if @reservation.save
      @students = @reservation.program.students 
      redirect_to add_passengers_path(@reservation), notice: "Reservation was successfully created. Please add passengers."
    else
      @sites = []
      @students = []
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /reservations/1 or /reservations/1.json
  def update
    if params[:reservation][:driver].present?
      @reservation.update(driver_id: Student.find(params[:reservation][:driver]).id)
      @students = @reservation.program.students - @reservation.passengers
      @students.delete(@reservation.driver)
      redirect_to add_passengers_path(@reservation)
      return
    end
    if params[:reservation][:backup_driver].present?
      @reservation.update(backup_driver_id: Student.find(params[:reservation][:backup_driver]).id)
      @students = @reservation.program.students - @reservation.passengers
      @students.delete(@reservation.backup_driver)
      redirect_to add_passengers_path(@reservation)
      return
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

  def add_passengers
    unless is_admin?(current_user)
      driver = Student.find_by(program_id: @reservation.program_id, uniqname: current_user.uniqname)
      @reservation.update(driver_id: driver.id)
    end
    @passengers = @reservation.passengers
    @students = @reservation.program.students - @passengers
    @students.delete(@reservation.driver)
    @students.delete(@reservation.backup_driver)
  end

  def remove_passenger
    @reservation.passengers.delete(Student.find(params[:student_id]))
    @passengers = @reservation.passengers
    @students = @reservation.program.students - @passengers
    @students.delete(@reservation.driver)
    @students.delete(@reservation.backup_driver)
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

    # Only allow a list of trusted parameters through.
    def reservation_params
      params.require(:reservation).permit(:status, :start_time, :end_time, :recurring, :driver_phone, :backup_driver_phone, :number_of_people_on_trip)
    end
end
