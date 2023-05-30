class ReservationsController < ApplicationController
  before_action :auth_user
  before_action :set_reservation, only: %i[ show edit update destroy add_passengers remove_passenger]
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
  end

  # POST /reservations or /reservations.json
  def create
    fail
    @reservation = Reservation.new(reservation_params)

    respond_to do |format|
      if @reservation.save
        format.html { redirect_to reservation_url(@reservation), notice: "Reservation was successfully created." }
        format.json { render :show, status: :created, location: @reservation }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @reservation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /reservations/1 or /reservations/1.json
  def update
    respond_to do |format|
      if @reservation.update(reservation_params)
        format.html { redirect_to reservation_url(@reservation), notice: "Reservation was successfully updated." }
        format.json { render :show, status: :ok, location: @reservation }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @reservation.errors, status: :unprocessable_entity }
      end
    end
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
