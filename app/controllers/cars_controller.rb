class CarsController < ApplicationController
  before_action :set_car, only: %i[ show edit update destroy ]

  # GET /cars or /cars.json
  def index
    @cars = Car.all
  end

  # GET /cars/1 or /cars/1.json
  def index
  end
  
  def show
  end


  # GET /cars/new
  def new
    @add_cars = Car.all - @car_program.cars
    @car = Car.new
    session[:return_to] = request.referer
  end

  # GET /cars/1/edit
  def edit
    session[:return_to] = request.referer
  end

  # POST /cars or /cars.json
  def create
    if params[:car_id].present?
      @car = Car.find(params[:car_id])
    else
     @car = Car.new(car_params)
    end

    respond_to do |format|
      if @car.save
        @car_program.cars << @car
        format.turbo_stream { redirect_to session.delete(:return_to),
        notice: "A new car was added"
                            }
      else
        format.turbo_stream { redirect_to session.delete(:return_to),
          alert: "Fail: you need to enter a car data" 
        }
      end
    end
  end

  # PATCH/PUT /cars/1 or /cars/1.json
  def update
    @car = Car.find(params[:id])

    respond_to do |format|
      if @car.update(car_params)
        format.turbo_stream { redirect_to session.delete(:return_to),
                              notice: "The car was added" 
                            }
      else
        format.turbo_stream { redirect_to session.delete(:return_to),
          alert: "Fail" 
        }
      end
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
    end

    # Only allow a list of trusted parameters through.
    def car_params
      params.require(:car).permit(:car_number, :make, :model, :color, :number_of_seats, :mileage, :gas, :parking_spot, :last_used, :last_checked, :last_driver, :car_id)
    end
end
