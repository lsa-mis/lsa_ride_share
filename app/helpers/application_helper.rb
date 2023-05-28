module ApplicationHelper

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

  def show_user_name_by_id(id)
    User.find(id).display_name_email
  end

  def updated_on_and_by(resource)
    return "Updated on " + resource.updated_at.strftime('%m/%d/%Y') + " by " + show_user_name_by_id(resource.updated_by)
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
    UnitPreference.where(unit_id: unit_id, name: "faculty_survey").present? && UnitPreference.where(unit_id: unit_id, name: "faculty_survey").pluck(:value).include?(true)
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

  def available_ranges(car, day)
    car_available = []
    day_begin = DateTime.new(day.year, day.month, day.day, 8, 0, 0, 'EDT')
    day_end = DateTime.new(day.year, day.month, day.day, 17, 0, 0, 'EDT')
    space_begin = day_begin
    car_day_reserv = car.reservations.where("start_time BETWEEN ? AND ?", day.beginning_of_day, day.end_of_day).order(:start_time)
    if car_day_reserv.present?
      day_ranges = car_day_reserv.map { |res| res.start_time..res.end_time }
      day_ranges.each do |range|
        if space_begin < range.begin
          r = space_begin..range.begin
          car_available << show_time_range(r)
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

  def show_time_range(day_range)
    "#{day_range.begin.strftime("%I:%M%p")} - #{day_range.end.strftime("%I:%M%p")}"
  end
  
  def render_flash_stream
    turbo_stream.update "flash", partial: "layouts/notification"
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

end
