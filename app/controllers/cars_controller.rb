class CarsController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :set_car, only: %i[ show edit update destroy ]
  before_action :set_statuses, only: %i[ new edit create update]

  # GET /cars or /cars.json
  def index
    @cars = Car.all
    authorize @cars
    
  end

  def show
  end

  # GET /cars/new
  def new
    @car = Car.new
    authorize @car
  end

  # GET /cars/1/edit
  def edit
  end

  # POST /cars or /cars.json
  def create
    @car = Car.new(car_params)
    authorize @car
    if @car.save
      redirect_to car_path(@car), notice: "A new car was added"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /cars/1 or /cars/1.json
  def update
    if @car.update(car_params)
      redirect_to car_path(@car), notice: "The car was updated"
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

    # Only allow a list of trusted parameters through.
    def car_params
      params.require(:car).permit(:car_number, :make, :model, :color, :number_of_seats, :mileage, :gas, :parking_spot, :last_used, :last_checked, :last_driver, :status, initial_damages: [])
    end
end
