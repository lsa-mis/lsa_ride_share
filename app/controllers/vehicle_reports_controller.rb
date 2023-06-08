class VehicleReportsController < ApplicationController
  before_action :auth_user
  before_action :set_units
  before_action :set_vehicle_report, only: %i[ show edit update destroy ]

  # GET /vehicle_reports or /vehicle_reports.json
  def index
    @cars = Car.all
    @terms = Term.sorted

    if params[:car_id].present?
      ids = Reservation.where(car_id: params[:car_id]).pluck(:id)
      @vehicle_reports = VehicleReport.where(reservation_id: ids)
    else
      @vehicle_reports = VehicleReport.all
    end

    if params[:unit_id].present?
      car_ids = Car.where(unit_id: params[:unit_id]).pluck(:id)
      reservation_ids = Reservation.where(car_id: car_ids)
      @vehicle_reports = VehicleReport.where(reservation_id: reservation_ids)
    else
      @vehicle_reports = VehicleReport.all
    end


    

    authorize @vehicle_reports
  end

  # GET /vehicle_reports/1 or /vehicle_reports/1.json
  def show
  end

  def delete_file_attachment
    @delete_file = ActiveStorage::Attachment.find(params[:id])
    @delete_file.purge
    redirect_back(fallback_location: request.referer)
  end


  # GET /vehicle_reports/new
  def new
    @vehicle_report = VehicleReport.new
    authorize @vehicle_report

    @vehicle_report.mileage_start = @reservation.car.mileage
    @vehicle_report.gas_start = @reservation.car.gas
    @vehicle_report.parking_spot = @reservation.car.parking_spot

    @pictures_start_required = false

    if @reservation.program.pictures_required_start
      @pictures_start_required = true
    end 
    
    if @reservation.program.pictures_required_end
      @pictures_end_required = true
    end

  end

  # GET /vehicle_reports/1/edit
  def edit
    @reservation = @vehicle_report.reservation

    if @reservation.program.pictures_required_start
      @pictures_start_required = true
    end 

    if @reservation.program.pictures_required_end
     @pictures_end_required = true
   end 

  end

  # POST /vehicle_reports or /vehicle_reports.json
  def create
    @vehicle_report = VehicleReport.new(vehicle_report_params)
    authorize @vehicle_report

    respond_to do |format|
      if @vehicle_report.save
        format.html { redirect_to vehicle_report_url(@vehicle_report), notice: "Vehicle report was successfully created." }
        format.json { render :show, status: :created, location: @vehicle_report }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @vehicle_report.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /vehicle_reports/1 or /vehicle_reports/1.json
  def update
    @reservation = @vehicle_report.reservation

    respond_to do |format|
      if @vehicle_report.update(vehicle_report_params)
        car = @vehicle_report.reservation.car
        if @vehicle_report.mileage_end.present?
          car.update(mileage: @vehicle_report.mileage_end)
        end

        if @vehicle_report.gas_end.present?
          car.update(gas: @vehicle_report.gas_end)
        end

        if @vehicle_report.parking_spot.present?
          car.update(parking_spot: @vehicle_report.parking_spot, last_used: DateTime.now, last_driver_id: @reservation.driver_id)
        end

        format.html { redirect_to vehicle_report_url(@vehicle_report), notice: "Vehicle report was successfully updated." }
        format.json { render :show, status: :ok, location: @vehicle_report }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @vehicle_report.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /vehicle_reports/1 or /vehicle_reports/1.json
  def destroy
    @vehicle_report.destroy

    respond_to do |format|
      format.html { redirect_to vehicle_reports_url, notice: "Vehicle report was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_vehicle_report
      @vehicle_report = VehicleReport.find(params[:id])
      authorize @vehicle_report
    end

    def set_units
      @units = Unit.where(id: current_user.unit_ids).order(:name)
    end

    # Only allow a list of trusted parameters through.
    def vehicle_report_params
      params.require(:vehicle_report).permit(:reservation_id, :mileage_start, :mileage_end, :gas_start, :gas_end, :parking_spot, :image_front_start, :image_driver_start, :image_passenger_start, :image_back_start, :image_front_end, :image_driver_end, :image_passenger_end, :image_back_end, :created_by, :updated_by, :status, :note, image_damages: [] )
    end
end
