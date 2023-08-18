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

    if params[:unit_id].present?
      unit_id = params[:unit_id]
      unit = Unit.find(unit_id).name
    end
    if params[:term_id].present?
      term_id = params[:term_id]
      term = Term.find(term_id).name
    end

    reporttype = params[:reporttype]
  
    @title = "LSA Rideshare System Report"

    if reporttype == 'totals_programs'
      sql = "SELECT program_id, (SELECT programs.title FROM programs WHERE res.program_id = programs.id) AS program, count(res.id) AS number_of_trips, sum(number_of_people_on_trip) AS number_of_students_on_trips, sum(vr.mileage_end - vr.mileage_start) AS mileage 
      FROM reservations AS res 
      join vehicle_reports AS vr on vr.reservation_id = res.id 
      JOIN programs ON programs.id = res.program_id         
      JOIN terms ON terms.id = programs.term_id
      JOIN units ON units.id = programs.unit_id" 
    else
      sql = "SELECT DISTINCT(vehicle_reports.id), (SELECT programs.title from programs WHERE res.program_id = programs.id) AS program, code AS term, terms.name AS term_name, reservation_id, start_time, end_time, 
      (SELECT TO_CHAR(AGE(end_time, start_time), 'DD \"Days\" HH24 \"Hours\" MI \"Minutes\"')) AS total_trip_time,
      (SELECT EXTRACT(EPOCH FROM (end_time - start_time)::INTERVAL)/60) AS total_trip_minutes,
      cars.car_number, 
      (SELECT sites.title FROM sites WHERE res.site_id = sites.id) AS site,
      (SELECT students.first_name || ' ' || students.last_name FROM students WHERE res.driver_id = students.id ) AS driver_name,
      (SELECT students.uniqname FROM students WHERE res.driver_id = students.id ) AS driver_uniqname, 
      driver_phone, 
      (SELECT students.first_name || ' ' || students.last_name FROM students WHERE res.backup_driver_id = students.id ) AS backup_driver_name,
      (SELECT students.uniqname FROM students WHERE res.backup_driver_id = students.id ) AS backup_driver_uniqname, 
      backup_driver_phone,
      (SELECT STRING_AGG(first_name || ' ' || last_name || ' (' || uniqname || ')', ', ' ) FROM students JOIN reservation_passengers ON reservation_passengers.student_id = students.id AND reservation_passengers.reservation_id = vehicle_reports.reservation_id) AS passengers,
      number_of_people_on_trip,
      mileage_start, 
      mileage_end,
      (SELECT ROUND((mileage_end - mileage_start)::numeric, 2)) AS mileage_total,
      gas_start, gas_end, vehicle_reports.parking_spot, parking_spot_return, vehicle_reports.status,
      (SELECT (CASE WHEN student_status = true THEN 'Completed' ELSE 'Not Completed' END)) AS student_completed_report,
      (SELECT (CASE WHEN vehicle_reports.approved  = true THEN 'Approved' ELSE 'Pending' END)) AS admin_approved,
      (CASE WHEN (SELECT exists(SELECT 1 from active_storage_attachments where record_type = 'VehicleReport' and name = 'image_damages' and record_id = vehicle_reports.id)) = true
        THEN 'Yes' ELSE 'No' END) AS car_damage,
      (SELECT email FROM users WHERE vehicle_reports.updated_by = users.id) AS last_updated_by FROM vehicle_reports
      JOIN reservations AS res ON res.id = vehicle_reports.reservation_id 
      JOIN cars ON cars.id = res.car_id
      JOIN programs ON programs.id = res.program_id
      JOIN terms ON terms.id = programs.term_id
      JOIN units ON units.id = programs.unit_id" 
    end

    where = " WHERE terms.id = " + term_id +  " AND  units.id = " + unit_id
    if params[:program_id].present?
      where += " AND programs.id = " + params[:program_id]
    end

    sql += where

    if reporttype == 'totals_programs'
      sql += " GROUP BY program_id "
    end

    records_array = ActiveRecord::Base.connection.exec_query(sql)

    @result = []
    @result.push({"report_name" => "vehicle_reports for #{unit} #{term}", "total" => records_array.count, "header" => records_array.columns, "rows" => records_array.rows})


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
          line << res['report_name'].titleize.upcase
          line << "Total number of records: " + res['total'].to_s
          csv << line
          header = res['header'].map! { |e| e.titleize.upcase }
          csv << header

          res['rows'].each do |h|
            h[0] = request.host + "/" + res['report_name'] + "/" + h[0].to_s

            #h[4] = request.host + "/reservations/" + h[4].to_s
            csv << h
          end
          csv << Array('')
        end
      end
    end

end
