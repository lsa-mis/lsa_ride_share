class CarsController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :auth_user
  before_action :set_car, only: %i[ show edit update destroy ]
  before_action :set_statuses, only: %i[ new edit create update]
  before_action :set_units

  # GET /cars or /cars.json
  def index
    if params[:unit_id].present?
      @cars = Car.where(unit_id: params[:unit_id]).order(:car_number)
    else
      @cars = Car.where(unit_id: current_user.unit_ids).order(:car_number)
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
    authorize @car
  end

  # GET /cars/1/edit
  def edit
    @last_checked = @car.last_checked.present? ? @car.last_checked.strftime("%Y-%m-%d %H:%M") : ""
  end

  # POST /cars or /cars.json
  def create
    @car = Car.new(car_params)
    authorize @car
    if @car.save
      redirect_to car_path(@car), notice: "A new car was added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /cars/1 or /cars/1.json
  def update
    fail
    if car_params[:is_checked_today] == "1"
      @car.last_checked = DateTime.now
    end
    if car_params[:is_checked_today] == "0" && car_params[:checked].present?
      @car.last_checked = car_params[:checked]
    end
    if @car.update(car_params.except(:is_checked_today, :checked))
      redirect_to car_path(@car), notice: "The car was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /cars/1 or /cars/1.json
  def destroy
    @car.destroy

    respond_to do |format|
      format.html { redirect_to cars_url, notice: "Car was successfully destroyed." }
      format.json { head :no_content }
    end
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

    # Only allow a list of trusted parameters through.
    def car_params
      params.require(:car).permit(:car_number, :make, :model, :color, :number_of_seats, 
                 :mileage, :gas, :parking_spot, :last_used, :checked, :last_driver_id, 
                 :updated_by, :status, :unit_id, :is_checked_today, initial_damages: [])
    end
end
