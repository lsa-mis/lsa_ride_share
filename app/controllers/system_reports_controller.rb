class SystemReportsController < ApplicationController
  before_action :auth_user

  def index
    @units = Unit.where(id: current_user.unit_ids).order(:name)
    # @terms = Term.current_and_future
    @terms = Term.all
    @vehicle_reports = []
    if params[:unit_id].present?
      @programs = Program.where(unit_id: params[:unit_id])
    else
      @programs = Program.where(unit_id: current_user.unit_ids)
    end
    @programs = @programs.data(params[:term_id])
    authorize :system_report
  end

  def run_report

    @vehicle_reports = VehicleReport.all
    if params[:unit_id].present?
      car_ids = Car.where(unit_id: params[:unit_id]).pluck(:id)
      reservation_ids = Reservation.where(car_id: car_ids)
      @vehicle_reports = VehicleReport.where(reservation_id: reservation_ids)
      @unit_id_select = params[:unit_id]
    end
    if params[:term_id].present?
      program_ids = Program.where(term_id: params[:term_id]).pluck(:id)
      reservation_ids = Reservation.where(program_id: program_ids)
      @vehicle_reports =  @vehicle_reports.where(reservation_id: reservation_ids)
      @term_id_select = params[:term_id]
    else
      program_ids = Program.current_term.pluck(:id)
      reservation_ids = Reservation.where(program_id: program_ids)
      @vehicle_reports =  @vehicle_reports.where(reservation_id: reservation_ids)
      @term_id_select = Program.current_term.pluck(:id) 
    end
    if params[:program_id].present?
      reservation_ids = Reservation.where(program_id: params[:program_id]).ids
      @vehicle_reports =  @vehicle_reports.where(reservation_id: reservation_ids)
      @program_id_select = params[:program_id]
    end

    # TODO - above query not working correctly - FALL 2023 shows an item but date is in JUNE

    @title = "LSA Rideshare System Report"

    # if params[:format] == "csv"

      sql = "SELECT DISTINCT(vehicle_reports.id), (SELECT programs.title from programs WHERE res.program_id = programs.id) AS program, code AS term, terms.name AS term_name, reservation_id, start_time, end_time, 
      (SELECT TO_CHAR(AGE(end_time, start_time), 'DD \"Days\" HH \"Hours\" MI \"Minutes\"')) AS total_trip_time,
      cars.car_number, 
      (SELECT students.first_name || ' ' || students.last_name FROM students WHERE res.driver_id = students.id ) AS driver_name,
      (SELECT students.uniqname FROM students WHERE res.driver_id = students.id ) AS driver_uniqname, 
      driver_phone, 
      (SELECT students.first_name || ' ' || students.last_name FROM students WHERE res.backup_driver_id = students.id ) AS backup_driver_name,
      (SELECT students.uniqname FROM students WHERE res.backup_driver_id = students.id ) AS backup_driver_uniqname, 
      backup_driver_phone,
      (SELECT STRING_AGG(first_name || ' ' || last_name || ' (' || uniqname || ')', ', ' ) FROM students JOIN reservation_passengers ON reservation_passengers.student_id = students.id AND reservation_passengers.reservation_id = vehicle_reports.reservation_id) AS passengers,
      mileage_start, 
      mileage_end,
      (SELECT mileage_end - mileage_start) AS mileage_total,
      gas_start, gas_end, vehicle_reports.parking_spot, parking_spot_return, vehicle_reports.status, student_status AS student_status_completed, vehicle_reports.approved AS admin_approved,
      (SELECT exists(SELECT 1 from active_storage_attachments where record_type = 'VehicleReport' and name = 'image_damages' and record_id = vehicle_reports.id)) AS car_damage,
      (SELECT email FROM users WHERE vehicle_reports.updated_by = users.id) AS last_updated_by FROM vehicle_reports
      JOIN reservations AS res ON res.id = vehicle_reports.reservation_id 
      JOIN cars ON cars.id = res.car_id
      JOIN programs ON programs.id = res.program_id
      JOIN terms ON terms.id = programs.term_id
      JOIN units ON units.id = programs.unit_id" 

      where = " WHERE terms.id = " + @term_id_select +  " AND  units.id = " + @unit_id_select
      if params[:program_id].present?
        where += " programs.id = " + @program_id_select
      end
      sql += where

      records_array = ActiveRecord::Base.connection.exec_query(sql)

      @result = []
      @result.push({"table" => "vehicle_report", "total" => records_array.count, "header" => records_array.columns, "rows" => records_array.rows})

    if params[:format] == "csv"
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

    def data_to_csv(result, title)
      CSV.generate(headers: true) do |csv|
        csv << Array(title)

        result.each do |res|
          line =[]
          line << res['table'].titleize.upcase
          line << "Total number of records: " + res['total'].to_s
          csv << line
          header = res['header'].map! { |e| e.titleize.upcase }
          csv << header

          res['rows'].each do |h|
            h[0] = request.host + "/" + res['table'] + "/" + h[0].to_s

            h[4] = request.host + "/reservations/" + h[4].to_s
            csv << h
          end
          csv << Array('')
        end
      end
    end

end
