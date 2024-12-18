class CarsController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :auth_user
  before_action :set_car, only: %i[ show edit update ]
  before_action :set_statuses, only: %i[ new edit create update]
  before_action :set_units

  # GET /cars or /cars.json
  def index
    if params[:unit_id].present?
      @cars = Car.where(unit_id: params[:unit_id]).order(:car_number)
    else
      @cars = Car.where(unit_id: current_user.unit_ids).order(:car_number)
    end
    if params[:car_status].present?
      @cars = @cars.where(status: params[:car_status])
    end
    authorize @cars
    
  end

  def show
    @reservations_past = @car.reservations_past
    @reservations_future = @car.reservations_future
  end

  # GET /cars/new
  def new
    @car = Car.new
    @parking_locations = []
    if @units.count == 1
      @unit_id = @units.first.id
      set_parking_locations(@unit_id)
    end
    authorize @car
  end

  # GET /cars/1/edit
  def edit
    @unit_id = @car.unit_id
    set_parking_locations(@unit_id)
  end

  # POST /cars or /cars.json
  def create
    @car = Car.new(car_params)
    if params[:parking_spot_select].present? && params[:parking_spot_select].downcase != "other"
      @car.parking_spot = params[:parking_spot_select]
    elsif params[:parking_spot].present?
      @car.parking_spot = params[:parking_spot]
    end
    authorize @car
    if @car.save
      redirect_to car_path(@car), notice: "A new car was added."
    else
      @unit_id = @car.unit_id
      set_parking_locations(@unit_id)
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /cars/1 or /cars/1.json
  def update
    @car.attributes = car_params
    if params[:parking_spot_select].present? && params[:parking_spot_select].downcase != "other"
      @car.parking_spot = params[:parking_spot_select]
    elsif params[:parking_spot].present?
      @car.parking_spot = params[:parking_spot]
    end
    if @car.save
      redirect_to car_path(@car), notice: "The car was updated."
    else
      @unit_id = @car.unit_id
      set_parking_locations(@unit_id)
      render :edit, status: :unprocessable_entity
    end
  end

  def get_parking_locations
    parking_prefs = UnitPreference.find_by(name: "parking_location", unit_id: params[:unit_id]).value
    parking_locations = []
    if parking_prefs.present?
      parking_locations = parking_prefs.split(',')
      parking_locations.each(&:strip!)
    end
    render json: parking_locations
    authorize Car
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_car
      @car = Car.find(params[:id])
      authorize @car
    end

    def set_statuses
      @statuses = Car.statuses.keys
    end

    def set_units
      @units = Unit.where(id: current_user.unit_ids).order(:name)
    end

    def set_parking_locations(unit_id)
      parking_prefs = UnitPreference.find_by(name: "parking_location", unit_id: unit_id).value
      @parking_locations = []
      if parking_prefs.present?
        @parking_locations = parking_prefs.split(',')
        @parking_locations.each(&:strip!)
      else 
        @other_parking = true
      end
    end

    # Only allow a list of trusted parameters through.
    def car_params
      params.require(:car).permit(:car_number, :make, :model, :color, :number_of_seats, 
                 :mileage, :gas, :parking_spot, :last_used, :checked, :last_driver_id, 
                 :updated_by, :status, :unit_id, :parking_note, initial_damages: [])
    end
end
