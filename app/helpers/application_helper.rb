module ApplicationHelper

  def root_path
    if user_signed_in?
      if is_student?(current_user)
        welcome_pages_student_path
      else
        all_root_path
      end
    else
      all_root_path
    end
  end
  
  def svg(svg)
    file_path = "app/assets/images/svg/#{svg}.svg"
    return File.read(file_path).html_safe if File.exist?(file_path)
    file_path
  end

  def show_date(field)
    field.strftime("%m/%d/%Y") unless field.blank?
  end

  def show_date_time(field)
    field.strftime("%m/%d/%Y %I:%M%p") unless field.blank?
  end

  def show_time(field)
    field.strftime("%I:%M%p") unless field.blank?
  end

  def show_user_name_by_id(id)
    User.find(id).display_name_email
  end

  def updated_on_and_by(resource)
    return "Updated on " + resource.updated_at.strftime('%m/%d/%Y') + " by " + show_user_name_by_id(resource.updated_by)
  end

  def email_address(student)
    student.uniqname + "@umich.edu"
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

  def show_units(user)
    if is_super_admin?(user)
      "SuperAdmin"
    else
      Unit.where(id: current_user.unit_ids).pluck(:name).join(' ')
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

  def is_super_admin?(user)
    user.membership.include?('lsa-was-rails-devs')
  end

  def is_admin?(user)
    user.membership.present?
  end

  def is_manager?(user)
    Program.all.map { |p| p.all_managers.include?(user.uniqname) }.any?
  end

  def is_student?(user)
    Student.where(uniqname: user.uniqname, program: Program.current_term).present?
  end
  
  def show_car(reservation)
    if reservation.car.present?
      reservation.car.car_number
    else
      "No car selected"
    end
  end

  def show_driver(reservation)
    if reservation.driver.present?
      reservation.driver.display_name
    else
      "No driver selected"
    end
  end

  def show_reserved_by_in_week_calendar(reservation)
    User.find(reservation.reserved_by).display_name
  end

  def show_reservation(reservation)
    reservation.program.title + "\n" + reservation.site.title + "\n" +
    show_date_time(reservation.start_time + 15.minute) + "\n" +  show_date_time(reservation.end_time - 15.minute)
  end

  def show_backup_driver(reservation)
    if reservation.backup_driver.present?
      reservation.backup_driver.display_name
    else
      "No backup driver selected"
    end
  end

  def available_ranges(car, day, unit_id)
    # time renges when the car is available on the day
    times = show_time_begin_end(day, unit_id)
    day_begin  = times[0] - 15.minute
    day_end  = times[1] + 15.minute
    car_available = []
    space_begin = day_begin
    car_day_reserv = car.reservations.where("start_time BETWEEN ? AND ?", day.beginning_of_day, day.end_of_day).order(:start_time)
    if car_day_reserv.present?
      day_ranges = car_day_reserv.map { |res| res.start_time..res.end_time }
      day_ranges.each do |range|
        if space_begin == range.begin
          space_begin = range.end
        elsif space_begin < range.begin && range.begin - space_begin < 30
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

  def available_ranges_edit(car, day, unit_id, reservation)
    # time renges when the car is available on the day including time for reservation that student is editing
    # example: ["04:30PM - 05:00PM", "08:00AM - 11:00AM", "11:00AM - 04:30PM - current"]
    car_available = available_ranges(car, day, unit_id)
    r = reservation.start_time..reservation.end_time
    car_available << show_time_range(r, true)
    return car_available
  end

  def show_time_begin_end(day, unit_id)
    t_begin = UnitPreference.find_by(name: "reservation_time_begin", unit_id: unit_id).value
    t_begin = Time.parse(t_begin).strftime("%H").to_i
    t_end = UnitPreference.find_by(name: "reservation_time_end", unit_id: unit_id).value
    t_end = Time.parse(t_end).strftime("%H").to_i
    day_begin = DateTime.new(day.year, day.month, day.day, t_begin, 0, 0, 'EDT')
    day_end = DateTime.new(day.year, day.month, day.day, t_end, 0, 0, 'EDT')
    return [day_begin, day_end]
  end

  def show_time_range(day_range, current = false)
    if current
      "#{(day_range.begin + 15.minute).strftime("%I:%M%p")} - #{(day_range.end - 15.minute).strftime("%I:%M%p")} - current"
    else
      "#{(day_range.begin + 15.minute).strftime("%I:%M%p")} - #{(day_range.end - 15.minute).strftime("%I:%M%p")}"
    end
  end

  def show_time(time)
    "#{time.strftime("%I:%M%p")}"
  end

  def available?(car, range)
    day = range.begin.to_date
    day_reservations = car.reservations.where("start_time BETWEEN ? AND ?", day.beginning_of_day, day.end_of_day).order(:start_time)
    return true unless day_reservations.present?
    # to add 15 minutes to nother reservation. Time slot between two reservations should be 30 minutes
    car_ranges = day_reservations.map { |res| (res.start_time - 14.minute)..(res.end_time + 14.minute) }
    if car_ranges.any? { |r| r.overlaps?(range)}
      return false
    else
      return true
    end
  end

  def all_day_available_time(day, unit_id)
    # all day time renges for unit
    times = show_time_begin_end(day, unit_id)
    day_begin  = times[0] - 15.minute
    day_end  = times[1] + 15.minute
    day_times_with_15_min_steps = (day_begin.to_i..day_end.to_i).to_a.in_groups_of(15.minutes).collect(&:first).collect { |t| Time.at(t) }
    available_times_begin = day_times_with_15_min_steps.map { |t| [show_time(t), t.to_s] }
    available_times_begin.pop
    available_times_end = day_times_with_15_min_steps.map { |t| [show_time(t), t.to_s] }
    available_times_end.shift
    available_times = {:begin=>available_times_begin, :end=>available_times_end}
    return available_times
  end

  def available_time(day, cars, unit_id)
    # array of time with 15 minutes step available to reserve cars
    times = show_time_begin_end(day, unit_id)
    day_begin  = times[0]
    day_end  = times[1]
    day_times_with_15_min_steps = (day_begin.to_i..day_end.to_i).to_a.in_groups_of(15.minutes).collect(&:first).collect { |t| Time.at(t) }
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
    available_times = {:begin=>available_times_begin, :end=>available_times_end}
    return available_times
  end

  def available_cars(cars, range)
    available = []
    cars.each do |car|
      if available?(car, range)
        available << car
      end
    end
    return available
  end

  def allow_student_to_edit_reservation?(reservation)
    return false unless is_student?(current_user)
    return false unless Student.find_by(uniqname: current_user.uniqname, program_id: reservation.program).present?
    if ((reservation.start_time - DateTime.now)/3600).round > 72 
      return true
    else
      return false
    end
  end

  def future_reservation?(reservation)
    reservation.start_time > DateTime.now
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

  def calculate_mileage(vehicle_report)
    if vehicle_report.mileage_end.present?
      mileage_trip_total = vehicle_report.mileage_end - vehicle_report.mileage_start
    else
      mileage_trip_total = "N/A"
    end
      return mileage_trip_total
  end

  def default_reservation_for_students
    day = DateTime.now + 72.hours
    return day + 48.hours if day.saturday?
    return day + 24.hours if day.sunday?
    return day
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

  def time_list = ["12:00AM"] + (1..11).map {|h| "#{h}:00AM"}.to_a + ["12:00PM"] + (1..11).map {|h| "#{h}:00PM"}.to_a

end
