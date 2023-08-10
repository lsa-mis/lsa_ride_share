class SystemReportsController < ApplicationController
  before_action :auth_user
  before_action :set_units, :set_terms, :set_programs

  def index
    @vehicle_reports = []

    authorize :system_report
  end

  def run_report

    @vehicle_reports = VehicleReport.all

    if params[:unit_id].present?
      car_ids = Car.where(unit_id: params[:unit_id]).pluck(:id)
      reservation_ids = Reservation.where(car_id: car_ids)
      @vehicle_reports = VehicleReport.where(reservation_id: reservation_ids)
    end
    if params[:term_id].present?
      program_ids = Program.where(term_id: params[:term_id]).pluck(:id)
      reservation_ids = Reservation.where(program_id: program_ids)
      @vehicle_reports =  @vehicle_reports.where(reservation_id: reservation_ids)
    else
      program_ids = Program.current_term.pluck(:id)
      reservation_ids = Reservation.where(program_id: program_ids)
      @vehicle_reports =  @vehicle_reports.where(reservation_id: reservation_ids)
    end
    if params[:program_id].present?
      reservation_ids = Reservation.where(program_id: params[:program_id]).ids
      @vehicle_reports =  @vehicle_reports.where(reservation_id: reservation_ids)
    end



    @title = "LSA Rideshare System Report"

    if params[:format] == "csv"

      #sql = 'SELECT "vehicle_reports".* FROM "vehicle_reports"'



      #SELECT \"vehicle_reports\".* FROM \"vehicle_reports\" WHERE \"vehicle_reports\".\"reservation_id\" IN (SELECT \"reservations\".\"id\" FROM \"reservations\" WHERE \"reservations\".\"car_id\" IN (1, 2)) AND \"vehicle_reports\".\"reservation_id\" IN (SELECT \"reservations\".\"id\" FROM \"reservations\" WHERE \"reservations\".\"program_id\" = 1) AND \"vehicle_reports\".\"reservation_id\" IN (SELECT \"reservations\".\"id\" FROM \"reservations\" WHERE 1=0)"

      #records_array = ActiveRecord::Base.connection.exec_query(sql)


      data = rails_data_to_csv(@vehicle_reports)

      #@result = []
      #@result.push({"table" => "vehicle_report", "total" => records_array.count, "header" => records_array.columns, "rows" => records_array.rows})

    
      #data = data_to_csv(@result, @title)

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

    def rails_data_to_csv(result)
      headers = ["id", "Reservation id", "Mileage start", "Mileage end", "Fuel % (depart)", "Fuel % (return)", "Parking spot (depart)", "Created by", "Updated by", "Admin Status", "Created", "Last Updated", "Student Status Completed", "Admin Approved", "Parking Spot (return)"]

      CSV.generate(headers: true) do |csv|
        csv << headers
      
        result.each do |row|
          headers ||= row.headers
          csv << row.attributes.values
        end
      end

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
