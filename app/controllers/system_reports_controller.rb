class SystemReportsController < ApplicationController
  before_action :auth_user
  before_action :set_form_values

  def index
    authorize :system_report
    @reports_list = [
      {title: "Vehicle Reports", url: vehicle_reports_all_report_system_reports_path, description: "This report shows Vehicle Reports statistics" },
      {title: "Totals by Programs", url: totals_programs_report_system_reports_path, description: "This report shows totals by programs statistics" },
      {title: "Approved Drivers", url: approved_drivers_report_system_reports_path, description: "This report shows all approved drivers for selected term and unit" },
      {title: "Reservations for Student", url: reservations_for_student_report_system_reports_path, description: "This report shows all reservations for a selected student" },
      {title: "Import Reservations", url: import_reservations_report_system_reports_path, description: "This report shows Import Reservations Log statistics" },
    ]
  end

  def vehicle_reports_all_report
    handle_report(
      report_type: "vehicle_reports_all",
      authorization: :vehicle_reports_all_report?,
      show_student_filter: false,
      show_program_filter: true,
      show_date_filters: false,
      link: true,
      model_class: VehicleReport,
      url: "vehicle_report_path",
      csv_path: "vehicle_reports",
      csv_filename: 'vehicle_reports_report.csv'
    )
  end

  def totals_programs_report
    handle_report(
      report_type: "totals_programs",
      authorization: :totals_programs_report?,
      show_student_filter: false,
      show_program_filter: true,
      show_date_filters: false,
      link: false,
      csv_filename: 'totals_by_programs_report.csv'
    )
  end

  def approved_drivers_report
    handle_report(
      report_type: "approved_drivers",
      authorization: :approved_drivers_report?,
      show_student_filter: false,
      show_program_filter: true,
      show_date_filters: false,
      link: false,
      csv_filename: 'approved_drivers_report.csv'
    )
  end

  def reservations_for_student_report
    handle_report(
      report_type: "reservations_for_student",
      authorization: :reservations_for_student_report?,
      show_student_filter: true,
      show_program_filter: true,
      show_date_filters: false,
      link: true,
      model_class: Reservation,
      url: "reservation_path",
      csv_path: "reservations",
      csv_filename: 'reservations_for_student_report.csv'
    )
  end

  def import_reservations_report
    @report_type = "import_reservations"
    @show_student_filter = false
    @show_program_filter = false
    @show_date_filters = true
    @link = false
    authorize :system_report, :import_reservations_report?
    if params[:commit]
      collect_form_params
      @title = "Import Reservations Log Report"
      @import_logs = ImportReservationLog.where(unit_id: @unit_id, date: @from..@to).order(created_at: :desc)
      if @import_logs.present?
        @metrics = {
          ' ' => @title,
          'Total Import Logs' => @import_logs.count,
        }
        @headers = ["Date", "User", "Status", "Note"]
        @data = @import_logs.map do |log|
          [log.date.strftime("%Y-%m-%d %H:%M"), log.user, log.status, log.note]
        end
      else
        @data = nil
      end
    end
    keep_form_values
    respond_to do |format|
      format.html
      format.csv { send_data csv_data, filename: 'import_reservations_log_report.csv', type: 'text/csv' }
    end
  end

  private

    # Generic method to handle all report types and eliminate duplication
    def handle_report(options = {})
      @report_type = options[:report_type]
      @show_student_filter = options.fetch(:show_student_filter, false)
      @show_program_filter = options.fetch(:show_program_filter, true)
      @show_date_filters = options.fetch(:show_date_filters, false)
      @link = options.fetch(:link, false)
      @model_class = options[:model_class] if options[:model_class]
      @url = options[:url] if options[:url]
      
      authorize :system_report, options[:authorization]
      
      if params[:commit]
        if options[:custom_logic]
          # For reports with custom logic (like import_reservations)
          options[:custom_logic].call
        else
          # Standard report logic
          collect_form_params
          @result = get_result(options[:report_type])
          @title = @result[0]['report_name'].titleize
          @headers = @result[0]['header']
          @metrics = {
            ' ' => @title,
            'Total' => @result[0]['total'],
          }
          @data = @result[0]['rows']
        end
      else
        @data = nil
      end
      
      keep_form_values
      
      respond_to do |format|
        format.html
        csv_path = options[:csv_path]
        csv_filename = options[:csv_filename]
        format.csv { send_data csv_data(csv_path), filename: csv_filename, type: 'text/csv' }
      end
    end

    def set_form_values
      @units = Unit.where(id: session[:unit_ids]).order(:name)
      @terms = Term.sorted
      @programs = Program.where(unit_id: session[:unit_ids])
      @term_id = Term.current.present? ? Term.current[0].id : nil
      @programs = @programs.data(@term_id).order(:title)
      @students = []
      if params[:unit_id].present?
        @unit_id = params[:unit_id].to_i
        @unit = Unit.find(@unit_id).name
      end
      if params[:term_id].present?
        @term_id = params[:term_id].to_i
        @term = Term.find(@term_id).name
      end
      if params[:program_id].present?
        @program_id = params[:program_id].to_i
      end
      if params[:student_id].present?
        @student_id = params[:student_id].to_i
      end
      if params[:uniqname].present?
        @uniqname = params[:uniqname]
      end
      if params[:from].present?
        @from = params[:from]
      end
      if params[:to].present?
        @to = params[:to]
      end
    end

    def keep_form_values
      @units = Unit.where(id: session[:unit_ids]).order(:name)
      @terms = Term.sorted
      if params[:unit_id].present?
        @unit_id = params[:unit_id].to_i
        @unit = Unit.find(@unit_id).name
        @programs = Program.where(unit_id: @unit_id)
      else
        @programs = Program.where(unit_id: session[:unit_ids])
      end
      if params[:term_id].present?
        @term_id = params[:term_id].to_i
        @term = Term.find(@term_id).name
      else
        @term_id = Term.current.present? ? Term.current[0].id : nil
      end
      @programs = @programs.data(@term_id).order(:title)
      @students = []
      if params[:program_id].present?
        @program_id = params[:program_id].to_i
        @students = Program.find(params[:program_id]).students.order(:last_name)
      end
      if params[:student_id].present?
        @student_id = params[:student_id].to_i
      end
      if params[:uniqname].present?
        @uniqname = params[:uniqname]
      end
      if params[:from].present?
        @from = params[:from]
      end
      if params[:to].present?
        @to = params[:to]
      end
    end

    def collect_form_params
      if params[:unit_id].present?
      @unit_id = params[:unit_id].to_i
      @unit = Unit.find(@unit_id).name
      end
      if params[:term_id].present?
        @term_id = params[:term_id].to_i
        @term = Term.find(@term_id).name
      end
      if params[:program_id].present?
        @program_id = params[:program_id].to_i
      end
      if params[:student_id].present?
        @student_id = params[:student_id].to_i
      end
      if params[:uniqname].present?
        @uniqname = params[:uniqname]
      end
    end

    def csv_data(path = "")
      CSV.generate(headers: true) do |csv|
        next csv << ["No data found"] if !@data

        csv << [@title]
        csv << []
        @metrics && @metrics.each { |desc, value| csv << [desc, value] }

        csv << []
        csv << @headers
        @data.each do |row|
          if @link
            row[0] = URI.join(request.base_url + "/" + path + "/" + row[0].to_s)
          end
          csv << row
        end
      end
    end

    def get_result(report_type)
      if report_type == 'totals_programs'
        sql1 = create_query('totals_programs')
        sql2 = create_query('programs_unique_students')
        records_array1 = ActiveRecord::Base.connection.exec_query(sql1)
        records_array2 = ActiveRecord::Base.connection.exec_query(sql2)
        result = []
        rows = []
        rows2 = records_array2.rows
        
        records_array1.rows.each do |row1|
          program_id1 = row1[0]
          # remove program_id from result
          row1.shift
          row2 = rows2[0]
          program_id2 = row2[0]
          while program_id1 < program_id2 do
            # go to the next row in rows2
            rows2.shift
          end
          # remove program_id form the result (it exists in row1)
          row2.shift
          # remove duplicated uniqnames from string
          row2_edited = row2[0].split.reverse.uniq.reverse.join(' ')
          # count number of uniqnames in string
          n = row2_edited.split.size
          rows << row1 + [row2_edited] + [n]
          rows2.shift
        end
        records_array1.columns.shift
        records_array2.columns.shift
        columns = records_array1.columns + records_array2.columns + ["unique_users"]
        result.push({"report_name" => "#{report_type} for #{@unit} #{@term}", "total" => records_array1.count, "header" => columns, "rows" => rows})
        return result
      end

      if report_type == "reservations_for_student"
        if @uniqname.present?
          programs = Program.where(unit_id: @unit_id)
          programs = programs.data(@term_id)
          student_ids = []
          programs.each do |program|
            student_ids << program.students.where(uniqname: @uniqname).ids
          end
          student_ids.flatten!
          if student_ids.present?
            report_name = Student.find(student_ids.first).name + ": reservations for #{@unit} #{@term}"
          else
            report_name = @uniqname + ": reservations for #{@unit} #{@term}"
          end
          res1 = Reservation.where("approved = ? AND driver_id IN (?)", true, student_ids).order(:start_time)
          res3 = Reservation.joins(:passengers).where("reservations.approved = ? AND reservation_passengers.student_id IN (?) ", true, student_ids).order(:start_time)
        else
          report_name = Student.find(@student_id).name + ": reservations for #{@unit} #{@term}"
          program = Program.find(@program_id)
          reservations_ids = program.reservations.where("approved = ?", true).ids
          res1 = program.reservations.where("approved = ? AND driver_id = ?", true, @student_id).order(:start_time)
          res3 = Reservation.joins(:passengers).where("reservation_passengers.reservation_id in (?) AND reservation_passengers.student_id = ?", reservations_ids,  @student_id).order(:start_time)
        end
        rows = []
        result = []
        res1.map { |r| rows << [r.id, r.car.car_number, r.program.title, show_reservation_time(r), r.site.title, r.car.car_number, r.number_of_people_on_trip, "driver"] }
        res3.map { |r| rows << [r.id, r.car.car_number, r.program.title, show_reservation_time(r), r.site.title, r.car.car_number, r.number_of_people_on_trip, "passenger"] }
        columns = ["reservation", "car", "program", "reservation time", "site", "car", "number of people on trip", "role"]
        rows = rows.sort_by { |obj| obj[1] }
        result.push({"report_name" => report_name, "total" => rows.count, "header" => columns, "rows" => rows})
        return result
      end

      if report_type == 'vehicle_reports_all' || report_type == 'approved_drivers' 
        sql = create_query(report_type)
        return run_query(sql, report_type)
      end

    end

    def create_query(report_type)
      if report_type == 'totals_programs'
        sql = "SELECT program_id, (SELECT programs.title FROM programs WHERE res.program_id = programs.id) AS program,
            count(res.id) AS number_of_trips, round(CAST(float8(sum(vr.mileage_end - vr.mileage_start)) as numeric), 2) AS mileage, sum(number_of_people_on_trip) AS total_people_on_trips
          FROM reservations AS res
          join vehicle_reports AS vr on vr.reservation_id = res.id
          JOIN programs ON programs.id = res.program_id
          JOIN terms ON terms.id = programs.term_id
          JOIN units ON units.id = programs.unit_id
          WHERE terms.id = #{@term_id} AND  units.id = #{@unit_id}"
          if params[:program_id].present?
            sql += " AND programs.id = #{params[:program_id].to_i}"
          end
          sql += " GROUP BY program_id ORDER BY program_id"
      end
      if report_type == 'programs_unique_students'
        sql = "SELECT  program_id,
          (SELECT STRING_AGG(
            CONCAT((SELECT students.uniqname FROM students WHERE res.driver_id = students.id), ' ',
              ((CASE 
                WHEN res.driver_id IS NULL
                THEN
                (SELECT managers.uniqname FROM managers WHERE res.driver_manager_id = managers.id)
                ELSE
                (SELECT students.uniqname FROM students WHERE res.driver_id = students.id)
                END)), ' ',
              (SELECT STRING_AGG(uniqname, ' ')
                FROM students
                JOIN reservation_passengers ON reservation_passengers.student_id = students.id AND reservation_passengers.reservation_id = vehicle_reports.reservation_id)),  ' ')
                AS uniqnames)
          FROM vehicle_reports
          JOIN reservations AS res ON res.id = vehicle_reports.reservation_id
          JOIN cars ON cars.id = res.car_id
          JOIN programs ON programs.id = res.program_id
          JOIN terms ON terms.id = programs.term_id
          JOIN units ON units.id = programs.unit_id
          WHERE terms.id = #{@term_id} AND  units.id = #{@unit_id}"
          if params[:program_id].present?
            sql += " AND programs.id = #{params[:program_id].to_i}"
          end
          sql += " GROUP BY program_id ORDER BY program_id"
      end
      if report_type == 'vehicle_reports_all'
        sql = "SELECT DISTINCT(vehicle_reports.id), (SELECT programs.title from programs WHERE res.program_id = programs.id) AS program,
          code AS term, terms.name AS term_name, reservation_id, start_time, end_time, 
          (SELECT TO_CHAR(AGE(end_time, start_time), 'DD \"Days\" HH24 \"Hours\" MI \"Minutes\"')) AS total_trip_time,
          (SELECT EXTRACT(EPOCH FROM (end_time - start_time)::INTERVAL)/60) AS total_trip_minutes, cars.car_number,
          (SELECT sites.title FROM sites WHERE res.site_id = sites.id) AS site,
          (CASE 
          WHEN res.driver_id IS NULL
          THEN
          (SELECT managers.first_name || ' ' || managers.last_name FROM managers WHERE res.driver_manager_id = managers.id)
          ELSE
          (SELECT students.first_name || ' ' || students.last_name FROM students WHERE res.driver_id = students.id)
          END) AS driver_name,
          (CASE 
            WHEN res.driver_id IS NULL
            THEN
            (SELECT managers.uniqname FROM managers WHERE res.driver_manager_id = managers.id)
            ELSE
            (SELECT students.uniqname FROM students WHERE res.driver_id = students.id)
            END) AS driver_uniqname,
          driver_phone,
          (SELECT STRING_AGG(first_name || ' ' || last_name || ' (' || uniqname || ')', ', ')
          FROM students
          JOIN reservation_passengers ON reservation_passengers.student_id = students.id AND reservation_passengers.reservation_id = vehicle_reports.reservation_id)
          AS passengers,
          number_of_people_on_trip, mileage_start, mileage_end,
          (SELECT ROUND((mileage_end - mileage_start)::numeric, 2)) AS mileage_total,
          gas_start, gas_end, vehicle_reports.parking_spot, parking_spot_return, vehicle_reports.status,
          (SELECT (CASE WHEN student_status = true THEN 'Completed' ELSE 'Not Completed' END)) AS student_completed_report,
          (SELECT (CASE WHEN vehicle_reports.approved  = true THEN 'Approved' ELSE 'Pending' END)) AS admin_approved,
          (CASE WHEN (SELECT exists(SELECT 1 from active_storage_attachments where record_type = 'VehicleReport' and name = 'image_damages' and record_id = vehicle_reports.id)) = true
            THEN 'Yes' ELSE 'No' END) AS car_damage,
          (SELECT email FROM users WHERE vehicle_reports.updated_by = users.id) AS last_updated_by
        FROM vehicle_reports
        JOIN reservations AS res ON res.id = vehicle_reports.reservation_id
        JOIN cars ON cars.id = res.car_id
        JOIN programs ON programs.id = res.program_id
        JOIN terms ON terms.id = programs.term_id
        JOIN units ON units.id = programs.unit_id
        WHERE terms.id = #{@term_id} AND  units.id = #{@unit_id}"
        if params[:program_id].present?
          sql += " AND programs.id = #{params[:program_id].to_i}"
        end
        sql += " ORDER BY program, vehicle_reports.id"
      end

      if report_type == 'approved_drivers'
        sql = "SELECT programs.title AS program, 'Student' AS driver_type,
          students.first_name || ' ' || students.last_name AS driver_name,
          students.uniqname as uniqname,
          students.mvr_status,
          students.canvas_course_complete_date,
          students.meeting_with_admin_date
          FROM programs AS programs
          JOIN students AS students ON programs.id = students.program_id
          WHERE programs.term_id = #{@term_id} AND programs.unit_id = #{@unit_id}
            AND students.mvr_status LIKE 'Approved%' 
            AND students.canvas_course_complete_date IS NOT NULL AND students.meeting_with_admin_date IS NOT NULL"
        if params[:program_id].present?
          sql += " AND programs.id = #{params[:program_id].to_i}"
        end
        sql += " UNION
          SELECT programs.title AS program, 'Instructor' AS driver_type,
          managers.first_name || ' ' || managers.last_name AS driver_name,
          managers.uniqname as uniqname,
          managers.mvr_status,
          managers.canvas_course_complete_date,
          managers.meeting_with_admin_date
          FROM programs AS programs
          JOIN managers AS managers ON programs.instructor_id = managers.id
          WHERE programs.term_id = #{@term_id} AND programs.unit_id = #{@unit_id}
            AND managers.mvr_status LIKE 'Approved%' 
            AND managers.canvas_course_complete_date IS NOT NULL AND managers.meeting_with_admin_date IS NOT NULL"
        if params[:program_id].present?
          sql += " AND programs.id = #{params[:program_id].to_i}"
        end
        sql += " UNION
          SELECT programs.title AS program, 'Manager' AS driver_type,
          (managers.first_name || ' ' || managers.last_name) AS driver_name,
          managers.uniqname as uniqname,
          managers.mvr_status,
          managers.canvas_course_complete_date,
          managers.meeting_with_admin_date
          FROM programs AS programs
          JOIN managers_programs ON programs.id = managers_programs.program_id
          JOIN managers AS managers ON managers.id = managers_programs.manager_id
          WHERE programs.term_id = #{@term_id} AND programs.unit_id = #{@unit_id}
            AND managers.mvr_status LIKE 'Approved%'
            AND managers.canvas_course_complete_date IS NOT NULL AND managers.meeting_with_admin_date IS NOT NULL"
        if params[:program_id].present?
          sql += " AND programs.id = #{params[:program_id].to_i}"
        end
        sql += " ORDER BY program, driver_type, driver_name"
      end
      return sql
    end

    def run_query(sql, report_type)
      records_array = ActiveRecord::Base.connection.exec_query(sql)
      result = []
      result.push({"report_name" => "#{report_type} for #{@unit} #{@term}", "total" => records_array.count, "header" => records_array.columns, "rows" => records_array.rows})
      return result
    end

    def data_to_csv(result, title, link = false, path = "")
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
            if link
              h[0] = "https://" + request.host + "/" + path + "/" + h[0].to_s
            end
            csv << h
          end
          csv << Array('')
        end
      end
    end

end
