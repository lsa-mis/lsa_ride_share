class SystemReportsController < ApplicationController
  before_action :auth_user
  before_action :set_units, :set_terms, :set_programs

  def index
    @vehicle_reports = []

    authorize :system_report
  end

  def run_report

    all_records = true

    if params[:unit_id].present?
      car_ids = Car.where(unit_id: params[:unit_id]).pluck(:id)
      reservation_ids = Reservation.where(car_id: car_ids)
      @vehicle_reports = VehicleReport.where(reservation_id: reservation_ids)
      all_records = false
    end
    if params[:term_id].present?
      program_ids = Program.where(term_id: params[:term_id]).pluck(:id)
      reservation_ids = Reservation.where(program_id: program_ids)
      @vehicle_reports =  @vehicle_reports.where(reservation_id: reservation_ids)
      all_records = false
    end
    if params[:program_id].present?
      program_ids = Program.where(id: params[:program_id]).pluck(:id)
      reservation_ids = Reservation.where(program_id: program_ids)
      @vehicle_reports =  @vehicle_reports.where(reservation_id: reservation_ids)
      all_records = false
    end

    @title = "LSA Rideshare System Report"

    if params[:format] == "csv"

      if all_records = true
        sql = 'SELECT "vehicle_reports".* FROM "vehicle_reports"'
      else
        sql = @vehicle_reports 
      end

      records_array = ActiveRecord::Base.connection.exec_query(sql)
      @result = []
      @result.push({"table" => "vehicle_report", "total" => records_array.count, "header" => records_array.columns, "rows" => records_array.rows})
    
      data = data_to_csv(@result, @title)

      respond_to do |format|
        format.html
        format.csv { send_data data, filename: "LSARideShare-report-#{DateTime.now.strftime('%-d-%-m-%Y at %I-%M%p')}.csv" }
        end
    else
      render turbo_stream: turbo_stream.replace(
        :reportListing,
        partial: "system_reports/listing")
    end

    authorize :system_report
  end


  private

    def set_units
      if is_admin?(current_user)
      @units = Unit.where(id: current_user.unit_ids).order(:name)
      elsif is_manager?(current_user)
        manager = Manager.find_by(uniqname: current_user.uniqname)
        @units = Unit.where(id: manager.programs.pluck(:unit_id).uniq).order(:name)
      else
        @units = Unit.all
      end
    end

    def set_terms
      @terms = Term.current_and_future
    end

    def set_programs
      @programs = Program.where(unit_id: current_user.unit_ids)
    end

    def data_to_csv(result, title)
      CSV.generate(headers: false) do |csv|
        csv << Array(title)
        result.each do |res|
          line =[]
          line << res['table'].titleize.upcase
          line << "Total number of records: " + res['total'].to_s
          csv << line
          header = res['header'].map! { |e| e.titleize.upcase }
          csv << header
          res['rows'].each do |h|
            h[0] = "http://localhost:3000/" + res['table'] + "/" + h[0].to_s
            csv << h
          end
          csv << Array('')
        end
      end
    end

end
