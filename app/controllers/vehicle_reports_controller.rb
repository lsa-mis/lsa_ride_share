class VehicleReportsController < ApplicationController
  before_action :auth_user
  before_action :set_units
  before_action :set_vehicle_report, only: %i[ show edit update destroy upload_image upload_damage_images upload_damage_form ]

  # GET /vehicle_reports or /vehicle_reports.json
  def index
    @terms = Term.sorted
    if params[:unit_id].present?
      @cars = Car.where(unit_id: params[:unit_id]).order(:car_number)
    else
      @cars = Car.where(unit_id: session[:unit_ids]).order(:car_number)
    end
    car_ids = @cars.pluck(:id)
    reservation_ids = Reservation.where(car_id: car_ids)
    @vehicle_reports = VehicleReport.where(reservation_id: reservation_ids).order(id: :desc)

    if params[:term_id].present?
      program_ids = Program.where(term_id: params[:term_id]).pluck(:id)
    else
      program_ids = Program.current_term.pluck(:id)
    end
    reservation_ids = Reservation.where(program_id: program_ids)
    @vehicle_reports =  @vehicle_reports.where(reservation_id: reservation_ids)

    if params[:car_id].present?
      ids = Reservation.where(car_id: params[:car_id]).pluck(:id)
      @vehicle_reports = @vehicle_reports.where(reservation_id: ids)
    end
    authorize @vehicle_reports
  end

  # GET /vehicle_reports/1 or /vehicle_reports/1.json
  def show
    @reservation = @vehicle_report.reservation
  end

  # GET /vehicle_reports/new
  def new
    @vehicle_report = VehicleReport.new
    @vehicle_report.parking_spot = @reservation.car.parking_spot
    unit = @reservation.program.unit
    parking_prefs = UnitPreference.find_by(name: "parking_location", unit_id: unit).value
    if parking_prefs.present?
      @parking_locations = parking_prefs.split(',')
      @parking_locations.each(&:strip!)
    end

    authorize @vehicle_report
  end

  # GET /vehicle_reports/1/edit
  def edit
    if @vehicle_report.approved
      flash.now[:alert] = 'The vehicle report is approved. Please reload the page. To edit, please contact your administrator.'
      render turbo_stream: turbo_stream.update("flash", partial: "layouts/notification")
    end
    @reservation = @vehicle_report.reservation
    unit = @reservation.program.unit
    parking_prefs = UnitPreference.find_by(name: "parking_location", unit_id: unit).value
    if parking_prefs.present?
      @parking_locations = parking_prefs.split(',')
      @parking_locations.each(&:strip!)
      if @parking_locations.map(&:downcase).include?("other")
        @other = true
      else 
        @other = false
      end
      if @vehicle_report.parking_spot_return.present? && @parking_locations.exclude?(@vehicle_report.parking_spot_return)
        @current_parking_return = @vehicle_report.parking_spot_return
      else
        @current_parking_return = ""
      end
    end
  end

  # POST /vehicle_reports or /vehicle_reports.json
  def create
    @vehicle_report = VehicleReport.new(vehicle_report_params)
    if params[:parking_spot_return_select].present? && params[:parking_spot_return_select].downcase != "other"
      @vehicle_report.parking_spot_return = params[:parking_spot_return_select]
    elsif params[:parking_spot_return].present?
      @vehicle_report.parking_spot_return = params[:parking_spot_return]
    end
    authorize @vehicle_report
    respond_to do |format|
      if @vehicle_report.save
        car = @reservation.car
        if @vehicle_report.mileage_end.present?
          car.update(mileage: @vehicle_report.mileage_end)
        end
        if @vehicle_report.gas_end.present?
          car.update(gas: @vehicle_report.gas_end)
        end
        if @vehicle_report.parking_spot_return.present?
          car.update(parking_spot: @vehicle_report.parking_spot_return, last_used: DateTime.now, last_driver_id: @reservation.driver_id)
        end
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
    @vehicle_report.attributes = vehicle_report_params
    if params[:parking_spot_return_select].present? && params[:parking_spot_return_select].downcase != "other"
      @vehicle_report.parking_spot_return = params[:parking_spot_return_select]
    elsif params[:parking_spot_return].present?
      @vehicle_report.parking_spot_return = params[:parking_spot_return]
    end
    respond_to do |format|
      if @vehicle_report.update(vehicle_report_params)
        car = @vehicle_report.reservation.car
        if @vehicle_report.mileage_end.present?
          car.update(mileage: @vehicle_report.mileage_end)
        end
        if @vehicle_report.gas_end.present?
          car.update(gas: @vehicle_report.gas_end)
        end
        if @vehicle_report.parking_spot_return.present?
          car.update(parking_spot: @vehicle_report.parking_spot_return, last_used: DateTime.now, last_driver_id: @reservation.driver_id)
        end
        format.html { redirect_to vehicle_report_url(@vehicle_report), notice: "Vehicle report was successfully updated." }
        format.json { render :show, status: :ok, location: @vehicle_report }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @vehicle_report.errors, status: :unprocessable_entity }
      end
    end
  end

  def upload_image
    if @vehicle_report.update(vehicle_report_params)
      @image_field_name = params[:vehicle_report].keys[0]
      @image_name = @vehicle_report.send(params[:vehicle_report].keys[0].to_sym)
    else
      render turbo_stream: turbo_stream.update("image_errors_#{params[:vehicle_report].keys[0]}", partial: "image_errors", locals: { image_field_name: params[:vehicle_report].keys[0] })
    end
  end

  def upload_damage_images
    if @vehicle_report.update(vehicle_report_params)
      render turbo_stream: turbo_stream.update("images_damage", partial: "images_damage")
    else
      render turbo_stream: turbo_stream.update("image_errors_image_damages", partial: "image_errors", locals: { image_field_name: 'image_damages' })
    end
  end

  def delete_image
    delete_file = ActiveStorage::Attachment.find(params[:image_id])
    delete_file.purge
    @vehicle_report = VehicleReport.find(params[:id])
    @vehicle_report.update(student_status: false)
    @image_field_name = params[:image_field_name]
    @image_name = @vehicle_report.send(params[:image_field_name].to_sym)
    authorize @vehicle_report
  end

  def destroy
    unless @vehicle_report.approved
      respond_to do |format|
        if @vehicle_report.destroy
          if is_admin?(current_user)
            format.html { redirect_to vehicle_reports_url, notice: "Vehicle report was canceled." }
            format.json { head :no_content }
          elsif is_student?(current_user)
            format.html { redirect_to welcome_pages_student_url, notice: "Vehicle report was canceled." }
            format.json { head :no_content }
          end
        else
          format.html { render :show, status: :unprocessable_entity }
          format.json { render json: @vehicle_report.errors, status: :unprocessable_entity }
        end
      end
    else
      flash.now[:alert] = 'The vehicle report is approved. Please reload the page. To cancel, please contact your administrator'
      render turbo_stream: turbo_stream.update("flash", partial: "layouts/notification")
    end
  end

  def download_vehicle_damage_form
    send_file Rails.root.join("public", "vehicle_damage.pdf"), :type=>"application/pdf", :x_sendfile=>true
    authorize VehicleReport
  end

  def upload_damage_form
    if @vehicle_report.update(vehicle_report_params)
    else
      render turbo_stream: turbo_stream.update("image_errors_damage_form", partial: "image_errors", locals: { image_field_name: 'damage_form' })
    end
  end

  def delete_damage_form
    delete_file = ActiveStorage::Attachment.find(params[:image_id])
    delete_file.purge
    @vehicle_report = VehicleReport.find(params[:id])
    authorize @vehicle_report
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_vehicle_report
      @vehicle_report = VehicleReport.find(params[:id])
      authorize @vehicle_report
    end

    def set_units
      @units = Unit.where(id: session[:unit_ids]).order(:name)
    end

    # Only allow a list of trusted parameters through.
    def vehicle_report_params
      params.require(:vehicle_report).permit(:reservation_id, :mileage_start, :mileage_end, 
                    :gas_start, :gas_end, :parking_spot, :parking_spot_return, :parking_spot_return_select, :image_front_start, :image_driver_start, 
                    :image_passenger_start, :image_back_start, :image_front_end, :image_driver_end, 
                    :image_passenger_end, :image_back_end, :created_by, :updated_by, :status, :comment,
                    :approved, :damage_form, image_damages: [] )
    end
end
