module ApplicationHelper
  include ActionView::Helpers::TagHelper

  def root_path
    if user_signed_in?
      if is_admin?
        all_root_path
      elsif is_manager?
        welcome_pages_manager_path
      elsif is_student?
        welcome_pages_student_path
      else
        all_root_path
      end
    else
      all_root_path
    end
  end

  def show_date(field)
    field.strftime("%m/%d/%Y") unless field.blank?
  end

  def show_date_with_month_name(field)
    field.to_date.strftime("%B %d, %Y") unless field.blank?
  end

  def show_date_time(field)
    field.strftime("%m/%d/%Y %I:%M%p") unless field.blank?
  end

  def show_reservation_start_time(reservation, date)
    if reservation.start_time.to_date == reservation.end_time.to_date 
      (reservation.start_time + 15.minute).strftime("%I:%M%p")
    else
      if date == reservation.start_time.to_date
        (reservation.start_time + 15.minute).strftime("%I:%M%p")
      else
        ""
      end
    end
  end

  def show_reservation_end_time(reservation, date)
    if reservation.start_time.to_date == reservation.end_time.to_date
      (reservation.end_time - 15.minute).strftime("%I:%M%p")
    else
      if date == reservation.end_time.to_date
        (reservation.end_time - 15.minute).strftime("%I:%M%p")
      else
        ""
      end
    end
  end

  def show_user_name_by_id(id)
    id ? User.find(id).display_name_email : "unknown"
  end

  def updated_on_and_by(resource)
    return "Updated on " + resource.updated_at.strftime('%m/%d/%Y at %I:%M%p') + " by " + show_user_name_by_id(resource&.updated_by)
  end

  def reserved_on_and_by(resource)
    return "Reserved on " + resource.created_at.strftime('%m/%d/%Y at %I:%M%p') + " by " + show_user_name_by_id(resource&.reserved_by)
  end

  def email_address(student)
    student.uniqname + "@umich.edu"
  end

  def need_to_check_mvr_status?(student)
    return true unless student.mvr_status.present?
    return true unless student.mvr_status.include? ("Approved until")
    status_date = student.mvr_status.split(" ").last.to_date
    return true if status_date < Date.today + 1.day
  end

  def number_of_students(program)
    if program.number_of_students.present? && program.number_of_students > 0
      program.number_of_students
    else
      "The student list is not populated"
    end
  end

  def number_of_students_using_ride_share(program)
    if program.number_of_students_using_ride_share.present?
      program.number_of_students_using_ride_share
    else
      "Not available"
    end
  end

  def unit_use_faculty_survey?(unit_id)
    UnitPreference.where(unit_id: unit_id, name: "faculty_survey").present? && UnitPreference.where(unit_id: unit_id, name: "faculty_survey").pluck(:on_off).include?(true)
  end

  def faculty_has_survey?(current_user)
    FacultySurvey.where(uniqname: current_user.uniqname).present?
  end

  def rich_text_value(field)
    field.body.html_safe.downcase
  end

  def rich_text_no_tags_value(field)
    strip_tags(field.body.to_s).strip
  end

  def has_answers?(faculty_survey)
    Survey.new(faculty_survey).has_answers?
  end
  
  def choose_managers_for_program(program)
    managers = Manager.all - program.managers
    managers.delete(program.instructor) if program.instructor.present?
    managers
  end

  def managers(program)
    if program.managers.present?
      managers = @program.managers.map{ |m| m.display_name }
    else
      managers = ["The program currently does not have any program managers."]
    end
    return managers
  end
  
  def choose_sites_for_program(program)
    sites = program.sites
    Site.where(unit_id: program.unit) - sites
  end

  def is_super_admin?
    session[:role] == "super_admin"
  end

  def is_admin?
    session[:role] == "admin" || session[:role] == "super_admin"
  end

  def is_manager?
    session[:role] == "manager"
  end

  def is_student?
    session[:role] == "student"
  end
  
  def show_car(reservation)
    if reservation.car.present?
      reservation.car.car_number
    else
      tags = html_escape('') # initialize an html safe string we can append to
      tags << content_tag(:i, nil, class: "fa-solid fa-triangle-exclamation", style: "color:#c53030;")
      tags << content_tag(:span, " No car selected", class: 'unavailable')
      tags
    end
  end

  def show_car_location(reservation)
    location = ""
    if reservation.car.present?
      location = reservation.car.parking_spot
      if reservation.car.parking_note.present?
        location += " - " + reservation.car.parking_note
      end
    end
    return location
  end

  def show_driver(reservation)
    if reservation.driver.present?
      reservation.driver.display_name
    elsif reservation.driver_manager.present?
      uniqname = Manager.find(reservation.driver_manager_id).uniqname
      reservation.driver_manager.display_name + show_manager(reservation.program, uniqname)
    else
      tags = html_escape('') # initialize an html safe string we can append to
      tags << content_tag(:i, nil, class: "fa-solid fa-triangle-exclamation", style: "color:#c53030;")
      tags << content_tag(:span, " No driver selected", class: 'unavailable')
      tags
    end
  end

  def no_good_driver?(reservation)
    driver_status_not_eligible?(reservation) || backup_driver_status_not_eligible?(reservation) || no_driver?(reservation)
  end

  def no_driver?(reservation)
    return false if reservation.driver.present? || reservation.driver_manager.present?
    return true
  end

  def driver_status_not_eligible?(reservation)
    if reservation.driver.present?
      return true unless reservation.driver.mvr_status.include?("Approved until")
    end
    if reservation.driver_manager.present?
      return true unless reservation.driver_manager.mvr_status.include?("Approved until")
    end
    return false
  end

  def display_driver_status(reservation)
    if driver_status_not_eligible?(reservation)
      tags = html_escape('') # initialize an html safe string we can append to
      tags << content_tag(:i, nil, class: "fa-solid fa-triangle-exclamation", style: "color:#c53030;")
      tags << content_tag(:span, " - expired MVR Status", class: 'unavailable')
      tags
    end
  end

  def show_backup_driver(reservation)
    if reservation.backup_driver.present?
      reservation.backup_driver.display_name
    else
      "No backup driver selected"
    end
  end

  def backup_driver_status_not_eligible?(reservation)
    if reservation.backup_driver.present?
      return true unless reservation.backup_driver.mvr_status.include?("Approved until")
    end
    return false
  end

  def display_backup_driver_status(reservation)
    if backup_driver_status_not_eligible?(reservation)
      tags = html_escape('') # initialize an html safe string we can append to
      tags << content_tag(:i, nil, class: "fa-solid fa-triangle-exclamation", style: "color:#c53030;")
      tags << content_tag(:span, " - expired MVR Status", class: 'unavailable')
      tags
    end
  end

  def show_last_driver(car)
    if car.last_driver_id.present?
      Student.find(car.last_driver_id).display_name
    else
      "No last driver"
    end
  end

  def show_manager(program, uniqname)
    if program.instructor.uniqname == uniqname
      return " (instructor)"
    elsif program.managers.pluck(:uniqname).include?(uniqname)
      return " (manager)"
    else
      return ""
    end
  end

  def show_reservation_time(reservation)
    if reservation.start_time.to_date == reservation.end_time.to_date
      show_date(reservation.start_time) + " " + show_time(reservation.start_time + 15.minute) + " - " + show_time(reservation.end_time - 15.minute)
    else
      show_date_time(reservation.start_time + 15.minute) + " - " + show_date_time(reservation.end_time - 15.minute)
    end
  end
  
  def show_reserved_by_in_week_calendar(reservation)
    if reservation.driver.present?
      reservation.driver.name
    elsif reservation.driver_manager.present?
      reservation.driver_manager.name
    else
      User.find(reservation.reserved_by).display_name
    end
  end

  def show_driver_phone_number(reservation)
    if reservation.driver.present?
      show_student_driver_phone(reservation)
    elsif reservation.driver_manager.present?
      show_manager_driver_phone(reservation)
    else
      return ""
    end
  end

  def show_student_driver_phone(reservation)
    if reservation.driver_phone.present?
      return reservation.driver_phone
    elsif reservation.driver.phone_number.present?
      return reservation.driver.phone_number
    end
  end

  def show_manager_driver_phone(reservation)
    if reservation.driver_phone.present?
      return reservation.driver_phone
    elsif reservation.driver_manager.phone_number.present?
      return reservation.driver_manager.phone_number
    end
  end

  def show_reservation(reservation)
    if recurring?(reservation)
      recurring = "Recurring - yes"
    else
      recurring = "Recurring - no"
    end
    if reservation.driver.present? || reservation.driver_manager.present?
      driver = "Driver: " + show_driver(reservation) + " (" + show_driver_phone_number(reservation) + ")"
      if driver_status_not_eligible?(reservation)
        driver += " - expired MVR Status"
      end
    else 
      driver = "No driver selected"
    end
    if reservation.backup_driver.present?
      backup_driver = "Backup Driver: " + show_backup_driver(reservation) + " (" + reservation.backup_driver_phone.to_s + ")"
      if backup_driver_status_not_eligible?(reservation)
        backup_driver += " - expired MVR Status"
      end
      backup_driver += "\n"
    else
      backup_driver = ""
    end
    if reservation.passengers.present? || reservation.passengers_managers.present?
      passengers = "Passengers: "
      reservation.passengers.each do |passenger|
        passengers += passenger.display_name + "\n"
      end
      reservation.passengers_managers.each do |passenger|
        passengers += passenger.display_name + show_manager(reservation.program, passenger.uniqname) + "\n"
      end
    else
      passengers = "No passengers"
    end
    if reservation.program.non_uofm_passengers && reservation.non_uofm_passengers.present?
      non_uofm_passengers = reservation.number_of_non_uofm_passengers.to_s + " Non UofM Passenge(s): " + reservation.non_uofm_passengers
    else
      non_uofm_passengers = ""
    end
    reservation.program.title + "\n" + reservation.site.title + "\n" +
    "From: " + show_date_time(reservation.start_time + 15.minute) + "\n" +  "To: " + show_date_time(reservation.end_time - 15.minute) + "\n" +
    recurring + "\n" + driver + "\n" + backup_driver +
    reservation.number_of_people_on_trip.to_s + " people on the trip" + "\n" +
    passengers + non_uofm_passengers
  end

  def available_ranges(car, day, unit_id)
    # time ranges when the car is available on the day
    day_begin  = unit_beginning_of_day(day, unit_id) - 15.minute
    day_end  = unit_end_of_day(day, unit_id) + 15.minute
    car_available = []
    car_whole_day = car.reservations.where("start_time < ? AND end_time > ?", day.beginning_of_day, day.end_of_day)
    if car_whole_day.present?
      return car_available
    end
    space_begin = day_begin
    car_day_reserv = car.reservations.where("start_time BETWEEN ? AND ? OR end_time BETWEEN ? AND ?", day.beginning_of_day, day.end_of_day, day.beginning_of_day, day.end_of_day).order(:start_time)
    if car_day_reserv.present?
      day_ranges = car_day_reserv.map { |res| res.start_time..res.end_time }
      day_ranges.each do |range|
        if space_begin == range.begin
          space_begin = range.end
        elsif space_begin < range.begin && (range.begin - space_begin)/1.minute > 30
          r = space_begin..range.begin
          car_available << show_time_range(r)
          space_begin = range.end
        else
          space_begin = range.end
        end
      end
      if space_begin < day_end
        r = space_begin..day_end
        car_available << show_time_range(r)
      end
    else
      r = day_begin..day_end
      car_available << show_time_range(r)
    end
    return car_available
  end

  def available_ranges_long(car, day_start, day_end, unit_id)
    # time renges when the car is available from day_start to day_end
    day_start_beginning = unit_beginning_of_day(day_start, unit_id) - 15.minute
    day_start_finish = unit_end_of_day(day_start, unit_id) + 15.minute

    day_end_beginning = unit_beginning_of_day(day_end, unit_id) - 15.minute
    day_end_finish = unit_end_of_day(day_end, unit_id) + 15.minute
    car_available = []
    car_whole_day_beginning = car.reservations.where("start_time < ? AND end_time > ?", day_start_beginning, day_start_finish)
    car_whole_day_finish = car.reservations.where("start_time < ? AND end_time > ?", day_end_beginning, day_end_finish)
    if car_whole_day_beginning.present? || car_whole_day_finish.present?
      return car_available
    end
    day_start_reservation = car.reservations.where(start_time: day_start_beginning..day_start_finish).order(end_time: :desc).first
    day_end_reservation = car.reservations.where(start_time: day_end_beginning..day_end_finish).order(:start_time).first

    if day_start_reservation.present?
      range_start = day_start_reservation.end_time
    else
      range_start = day_start_beginning
    end

    if day_end_reservation.present?
      range_end = day_end_reservation.start_time
    else
      range_end = day_end_finish
    end

    car_available << show_time_range_long(range_start..range_end)
    return car_available
  end

  def available_ranges_edit(car, day, unit_id, reservation)
    # time renges when the car is available on the day including time for reservation that student is editing
    # example: ["04:30PM - 05:00PM", "08:00AM - 11:00AM", "11:00AM - 04:30PM - current"]
    car_available = available_ranges(car, day, unit_id)
    r = Reservation.find(reservation.id).start_time..Reservation.find(reservation.id).end_time
    car_available << show_time_range(r, true)
    return car_available
  end

  def available_ranges_long_edit(car, day_start, day_end, unit_id, reservation)
    # time renges when the car is available on the day including time for reservation that student is editing
    # example: ["04:30PM - 05:00PM", "08:00AM - 11:00AM", "11:00AM - 04:30PM - current"]
    car_available = available_ranges_long(car, day_start, day_end, unit_id)
    r = Reservation.find(reservation.id).start_time..Reservation.find(reservation.id).end_time
    car_available << show_time_range_long(r, true)
    return car_available
  end

  def unit_beginning_of_day(day, unit_id)
    # earliest time from Unit Preferences to create reservation 
    t_begin = UnitPreference.find_by(name: "reservation_time_begin", unit_id: unit_id).value
    t_begin = Time.parse(t_begin).strftime("%H").to_i
    if (day.to_time + 2.hour).dst?
      day_begin = DateTime.new(day.year, day.month, day.day, t_begin, 0, 0, 'EDT')
    else
      day_begin = DateTime.new(day.year, day.month, day.day, t_begin, 0, 0, 'EST')
    end
    return day_begin
  end

  def unit_end_of_day(day, unit_id)
    # latest time from Unit Preferences to create reservation 
    t_end = UnitPreference.find_by(name: "reservation_time_end", unit_id: unit_id).value
    t_end = Time.parse(t_end).strftime("%H").to_i
    if (day.to_time + 2.hour).dst?
      day_end = DateTime.new(day.year, day.month, day.day, t_end, 0, 0, 'EDT')
    else
      day_end = DateTime.new(day.year, day.month, day.day, t_end, 0, 0, 'EST')
    end
    return day_end
  end

  def show_time_range(day_range, current = false)
    # show avalable time range or current reservation range
    if (day_range.begin + 15.minute).strftime("%I:%M%p") == (day_range.end - 15.minute).strftime("%I:%M%p")
      return ""
    end
    if current
      "#{(day_range.begin + 15.minute).strftime("%I:%M%p")} - #{(day_range.end - 15.minute).strftime("%I:%M%p")} - current"
    else
      "#{(day_range.begin + 15.minute).strftime("%I:%M%p")} - #{(day_range.end - 15.minute).strftime("%I:%M%p")}"
    end
  end

  def show_time_range_long(day_range, current = false)
    # show avalable time range or current reservation range
    if current
      "#{(day_range.begin + 15.minute).strftime("%I:%M%p")}(#{(day_range.begin).strftime("%b %d")}) - #{(day_range.end - 15.minute).strftime("%I:%M%p")}(#{(day_range.end).strftime("%b %d")}) - current"
    else
      "#{(day_range.begin + 15.minute).strftime("%I:%M%p")}(#{(day_range.begin).strftime("%b %d")}) - #{(day_range.end - 15.minute).strftime("%I:%M%p")}(#{(day_range.end).strftime("%b %d")})"
    end
  end

  def show_time(time)
    return "" unless time.present?
    "#{time.strftime("%I:%M%p")}"
  end

  def combine_day_and_time(day, time)
    # pass in a date and time or strings
    day = Date.parse(day) if day.is_a? String 
    time = Time.parse(time) if time.is_a? String
    if (day.to_date.to_time + 2.hour).dst?
      new_time = DateTime.new(day.year, day.month, day.day, time.hour, time.min, time.sec, 'EDT')
    else
      new_time = DateTime.new(day.year, day.month, day.day, time.hour, time.min, time.sec, 'EST')
    end
    return new_time
  end

  def available?(car, range)
    # if car is avalable for the time range
    range_begin = range.begin + 1.minute
    range_end = range.end - 1.minute
    if car.reservations.where("start_time BETWEEN ? AND ? OR end_time BETWEEN ? AND ?", range_begin, range_end, range_begin, range_end).present?
      return false 
    end
    if car.reservations.where("start_time < ? AND end_time > ?", range_begin, range_end).present?
      return false 
    end
    return true
  end

  def available_edit?(reservation_id, car, range)
    # if car is avalable for the time range - do not count the current reservation
    range_begin = range.begin + 1.minute
    range_end = range.end - 1.minute
    if car.reservations.where("id <> ? AND (start_time BETWEEN ? AND ? OR end_time BETWEEN ? AND ?)", reservation_id, range_begin, range_end, range_begin, range_end).present?
      return false 
    end
    if car.reservations.where("id <> ? AND (start_time < ? AND end_time > ?)", reservation_id, range_begin, range_end).present?
      return false 
    end
    return true
  end

  def all_day_available_time(day, unit_id)
    # all day time renges for unit
    day_begin = unit_beginning_of_day(day, unit_id)
    day_end = unit_end_of_day(day, unit_id)
    day_times_with_15_min_steps = (day_begin.to_i..day_end.to_i).to_a.in_groups_of(15.minutes).collect(&:first).collect { |t| Time.at(t).to_datetime }
    available_times_begin = day_times_with_15_min_steps.map { |t| [show_time(t), t.to_s] }
    available_times_begin.pop
    available_times_end = day_times_with_15_min_steps.map { |t| [show_time(t), t.to_s] }
    available_times_end.shift

    available_times = {:begin=>available_times_begin, :end=>available_times_end}
    return available_times
  end

  def available_time(day, cars, unit_id)
    unless cars.present?
      return all_day_available_time(day, unit_id)
    end
    # array of time with 15 minutes step available to reserve cars
    day_begin = unit_beginning_of_day(day, unit_id)
    day_end = unit_end_of_day(day, unit_id)
    day_times_with_15_min_steps = (day_begin.to_i..day_end.to_i).to_a.in_groups_of(15.minutes).collect(&:first).collect { |t| Time.at(t).to_datetime }
    available_times_begin = []
    available_times_end = []

    day_reservations = Reservation.where("start_time BETWEEN ? AND ?", day.beginning_of_day, day.end_of_day).order(:start_time)
    if day_reservations.present?
      day_times_with_15_min_steps.each do |step|
        range = step..step + 15.minutes
        cars.each do |car|
          if available?(car, range)
            available_times_begin << [show_time(step), step]
            available_times_end << [show_time(step + 15.minutes), step + 15.minutes]
            break
          end
        end
      end
    else
      available_times_begin = day_times_with_15_min_steps.map { |t| [show_time(t), t.to_s] }
      available_times_begin.pop
      available_times_end = day_times_with_15_min_steps.map { |t| [show_time(t), t.to_s] }
      available_times_end.shift
    end
    unless available_times_begin.present? || available_times_end.present?
      return all_day_available_time(day, unit_id)
    else
      available_times = {:begin=>available_times_begin, :end=>available_times_end}
      return available_times
    end
  end

  def available_cars(cars, range)
    # all cars available for the time range
    available = []
    cars.each do |car|
      if available?(car, range)
        available << car
      end
    end
    return available
  end
  
  def minimum_hours_before_reservation(unit_id)
    if UnitPreference.find_by(name: "hours_before_reservation", unit_id: unit_id).value.present?
      UnitPreference.find_by(name: "hours_before_reservation", unit_id: unit_id).value.to_i
    else
      24
    end
  end

  def allow_user_to_cancel_reservation?(reservation)
    if is_admin?
      return true
    elsif is_manager?
      manager = Manager.find_by(uniqname: current_user.uniqname)
      if reservation.driver_manager == manager && reservation.end_time > Date.today.beginning_of_day
        return true
      end 
    elsif is_student?
      student = Student.find_by(uniqname: current_user.uniqname, program_id: reservation.program)
      if (reservation.driver == student || reservation.backup_driver == student) && reservation.end_time > Date.today.beginning_of_day
        return true
      end
    else
      return false
    end
  end

  def is_in_reservation?(current_user, reservation)
    if is_manager?
      manager = Manager.find_by(uniqname: current_user.uniqname)
      return reservation.driver_manager == manager || reservation.reserved_by = current_user.id || reservation.passengers_managers.include?(manager)
    end
    if is_student?
      student = Student.find_by(program_id: reservation.program, uniqname: current_user.uniqname)
      return reservation.driver == student || reservation.backup_driver == student || reservation.passengers.include?(student)
    end
    return false
  end

  def allow_student_to_edit_reservations?(reservation)
    return false unless is_student?
    return false unless Student.find_by(uniqname: current_user.uniqname, program_id: reservation.program).present?
    student = Student.find_by(uniqname: current_user.uniqname, program_id: reservation.program)
    return false unless student.can_reserve_car?
    if (reservation.driver == student || reservation.backup_driver == student) && ((reservation.start_time - DateTime.now.beginning_of_day)/3600).round > minimum_hours_before_reservation(reservation.program.unit)
      return true
    else
      return false
    end
  end

  def allow_manager_to_edit_reservations?(reservation)
    return false unless is_manager?
    return false unless reservation.driver_manager_id.present?
    # return true if reservation.reserved_by = current_user.id
    if reservation.driver_manager.uniqname == current_user.uniqname && ((reservation.start_time - DateTime.now.beginning_of_day)/3600).round > minimum_hours_before_reservation(reservation.program.unit)
      return true
    else
      return false
    end
  end

  def allow_student_to_edit_passengers?(reservation)
    return false unless is_student?
    return false unless Student.find_by(uniqname: current_user.uniqname, program_id: reservation.program).present?
    student = Student.find_by(uniqname: current_user.uniqname, program_id: reservation.program)
    # return false unless student.can_reserve_car?
    # if (reservation.driver == student || reservation.backup_driver == student) && reservation.end_time + 45.minute > DateTime.now
    if (reservation.passengers.include?(student) || reservation.driver == student || reservation.backup_driver == student) && reservation.end_time + 45.minute > DateTime.now
      return true
    else
      return false
    end
  end

  def allow_manager_to_edit_passengers?(reservation)
    return false unless is_manager?
    return false unless reservation.driver_manager_id.present?
    return true if reservation.reserved_by = current_user.id
    # if reservation.driver_manager.uniqname == current_user.uniqname && reservation.end_time + 45.minute > DateTime.now
    manager = Manager.find_by(uniqname: current_user.uniqname)
    if (reservation.driver_manager == manager || reservation.passengers_managers.include?(manager)) && reservation.end_time + 45.minute > DateTime.now
      return true
    else
      return false
    end
  end
  
  def render_flash_stream
    turbo_stream.update "flash", partial: "layouts/notification"
  end

  def show_vehicle_report_student_status(vehicle_report)
    if vehicle_report.student_status
      "Completed"
    else
      "Not Completed"
    end
  end

  def allow_add_vehicle_report?(reservation, user)
    if is_admin?
      return true
    else
      if Reservation.no_or_not_complete_vehicle_reports.exists?(reservation.id)
        return true
      else
        return false
      end
    end
  end

  def calculate_mileage(vehicle_report)
    if vehicle_report.mileage_end.present?
      mileage_trip_total = vehicle_report.mileage_end - vehicle_report.mileage_start
      mileage_trip_total = (mileage_trip_total).round(2)
    else
      mileage_trip_total = "N/A"
    end
      return mileage_trip_total
  end

  def show_percentage(value)
    if value.present?
      value.to_s + "%"
    else
      ""
    end
  end

  def default_reservation_for_students(unit_id)
    day = DateTime.now + minimum_hours_before_reservation(unit_id).hours
    return day + 48.hours if day.saturday?
    return day + 24.hours if day.sunday?
    return day
  end

  def max_day_for_reservation(unit_id)
    if UnitPreference.find_by(unit_id: unit_id, name: "recurring_until")&.value.present? && is_date?(UnitPreference.find_by(unit_id: unit_id, name: "recurring_until").value)
      UnitPreference.find_by(unit_id: unit_id, name: "recurring_until").value.to_date
    else
      return Term.current.pluck(:classes_end_date).min
    end
  end

  def is_date?(string)
    return true if string.to_date
    rescue ArgumentError
      false
  end

  def contact_phone(reservation)
    reservation.program.unit.unit_preferences.find_by(name: "contact_phone").value.presence || ""
  end 

  def email_was_sent?(model, record)
    EmailLog.find_by(sent_from_model: model, record_id: record).present?
  end

  def show_image_name(image_field_name)
    return "Front of Car *" if image_field_name == "image_front_start"
    return "Driver Side *" if image_field_name == "image_driver_start"
    return "Passenger Side *" if image_field_name == "image_passenger_start"
    return "Back of Car *" if image_field_name == "image_back_start"
    return "Front of Car *" if image_field_name == "image_front_end"
    return "Driver Side *" if image_field_name == "image_driver_end"
    return "Passenger Side *" if image_field_name == "image_passenger_end"
    return "Back of Car *" if image_field_name == "image_back_end"
    return ""
  end

  def show_course(student)
    if student.course.present?
      student.course.display_name
    else
      ""
    end
  end

  def us_states
    [
      ['Alabama', 'AL'],
      ['Alaska', 'AK'],
      ['Arizona', 'AZ'],
      ['Arkansas', 'AR'],
      ['California', 'CA'],
      ['Colorado', 'CO'],
      ['Connecticut', 'CT'],
      ['Delaware', 'DE'],
      ['District of Columbia', 'DC'],
      ['Florida', 'FL'],
      ['Georgia', 'GA'],
      ['Hawaii', 'HI'],
      ['Idaho', 'ID'],
      ['Illinois', 'IL'],
      ['Indiana', 'IN'],
      ['Iowa', 'IA'],
      ['Kansas', 'KS'],
      ['Kentucky', 'KY'],
      ['Louisiana', 'LA'],
      ['Maine', 'ME'],
      ['Maryland', 'MD'],
      ['Massachusetts', 'MA'],
      ['Michigan', 'MI'],
      ['Minnesota', 'MN'],
      ['Mississippi', 'MS'],
      ['Missouri', 'MO'],
      ['Montana', 'MT'],
      ['Nebraska', 'NE'],
      ['Nevada', 'NV'],
      ['New Hampshire', 'NH'],
      ['New Jersey', 'NJ'],
      ['New Mexico', 'NM'],
      ['New York', 'NY'],
      ['North Carolina', 'NC'],
      ['North Dakota', 'ND'],
      ['Ohio', 'OH'],
      ['Oklahoma', 'OK'],
      ['Oregon', 'OR'],
      ['Pennsylvania', 'PA'],
      ['Puerto Rico', 'PR'],
      ['Rhode Island', 'RI'],
      ['South Carolina', 'SC'],
      ['South Dakota', 'SD'],
      ['Tennessee', 'TN'],
      ['Texas', 'TX'],
      ['Utah', 'UT'],
      ['Vermont', 'VT'],
      ['Virginia', 'VA'],
      ['Washington', 'WA'],
      ['West Virginia', 'WV'],
      ['Wisconsin', 'WI'],
      ['Wyoming', 'WY']
    ]
  end
  
  def gas_percent
    [
      ['12.5', '12.5'],
      ['25.0', '25.0'],
      ['37.5', '37.5'],
      ['50.0', '50.0'],
      ['62.5', '62.5'],
      ['75.0', '75.0'],
      ['87.5', '87.5'],
      ['100', '100.0']
    ]
  end

  def time_list 
    time_list = ["12:00AM"] + (1..11).map {|h| "#{h}:00AM"}.to_a + ["12:00PM"] + (1..11).map {|h| "#{h}:00PM"}.to_a
    time_list.shift
    return time_list
  end

  def recurring?(reservation)
    reservation.prev.present? || reservation.next.present? || reservation.recurring.present?
  end

  def reservation_color
    {false => "bg-red-900", true => "bg-green-900"}
  end

  def get_car_day_reservations_hash(day, car, unit_id)
    day_begin = unit_beginning_of_day(day, unit_id) - 15.minute
    day_end = unit_end_of_day(day, unit_id)
    day_times_with_15_min_steps = (day_begin.to_i..day_end.to_i).to_a.in_groups_of(15.minutes).collect(&:first).collect { |t| Time.at(t) }
    if car.present?
      car_day_reserv = car.reservations.where("(start_time BETWEEN ? AND ?) OR (start_time < ? AND end_time > ?)",
        day.beginning_of_day, day.end_of_day, day.beginning_of_day, day.beginning_of_day)
    else
      car_day_reserv = Reservation.where(program: Program.where(unit_id: unit_id), car_id: nil).where("(start_time BETWEEN ? AND ?) OR (start_time < ? AND end_time > ?)",
        day.beginning_of_day, day.end_of_day, day.beginning_of_day, day.beginning_of_day)
    end
    car_cells = {}
    day_times_with_15_min_steps.each do |step|
      start = []
      ending = []
      middle = []
      car_day_reserv.each do |r|
        if r.start_time == step
          start << r
        end
        if r.end_time - 15.minute == step
          ending << r
        end
        if (r.start_time + 15.minute..r.end_time - 16.minute).cover?(step)
          middle << r
        end
      end
      car_cells[step] = {:start => start, :middle => middle, :ending => ending }
    end
    return car_cells
  end

  def report_types
    {"Vehicle Reports" => "vehicle_reports_all", 
    "Totals by Program " => "totals_programs", 
    "Approved Drivers" => "approved_drivers",
    "Reservations for Student" => "reservations_for_student"}
  end

  def car_statuses
    [["Available", 0], ["Unavailable", 1]]
  end

  def user_role
    if is_super_admin?
      " - super admin"
    elsif is_admin?
      " - admin"
    elsif is_manager?
      " - manager"
    elsif is_student?
     ""
    else
      "- none"
    end
  end

  def managers_without_programs
    programs = Program.all
    i_ids = programs.pluck(:instructor_id).uniq
    instructors = Manager.where(id: i_ids)
    p_ids = programs.pluck(:id)
    managers = Manager.joins(:programs).where('managers_programs.program_id IN (?)', p_ids)
    managers_and_instructors = (instructors + managers).uniq
    all_managers = Manager.all
    return all_managers - managers_and_instructors
  end

  def cancel_reservation_form(cancel_type)
    if cancel_type == "single"
      form_with(url: cancel_reservation_path, method: :get, data: { turbo_frame: "_top" }) { |form| yield form }
    else
      form_with(url: cancel_recurring_reservation_path, method: :get, data: { turbo_frame: "_top" }) { |form| yield form }
    end
  end

  def show_current_terms
    terms = []
    current = Term.current
    if current.present?
      if current.count > 1
        terms = current.map { |term| term.display_name }
      else
        terms = [current.first.name, "(#{current.first.classes_begin_date.strftime('%m/%d/%Y')} - #{current.first.classes_end_date.strftime('%m/%d/%Y')})"]
      end
    else
      terms = "No current term"
    end
  end

end
