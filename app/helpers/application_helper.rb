module ApplicationHelper

  def default_config_questions
    [
      "Number of students using ride share",
      "<div>Type of car reservation&nbsp;</div><ul><li>Recurring</li><li>Sporadic</li><li>Events</li><li>Trips</li><li>Other</li></ul>",
      "Does The Course Have A $50 Lab Fee?",
      "<div>What training option would be best for your course? (~30-minutes needed)&nbsp;</div><ul><li>Whole Class In-Person (Recommended)&nbsp;</li><li>Whole Class Via Zoom (Recommended)&nbsp;</li><li>Small Groups Via Zoom&nbsp;</li><li>Individuals Sign Up Online&nbsp;</li><li>Other</li></ul>",
      "If whole class training is possible, what date would be best? (The admin will contact to coordinate time/location)"
    ]
  end

  def svg(svg)
    file_path = "app/assets/images/svg/#{svg}.svg"
    return File.read(file_path).html_safe if File.exist?(file_path)
    file_path
  end

  def show_date(field)
    field.strftime("%m/%d/%Y") unless field.blank?
  end

  def show_user_name_by_id(id)
    User.find(id).display_name_email
  end

  def program_config_data(program)
    config_data = ''
    if program.pictures_required_start || program.pictures_required_end
      config_data = 'The program requires to upload pictures to the vehicle reports '
      if program.pictures_required_start
        config_data += 'at the start of the trip '
      end
      if program.pictures_required_start && program.pictures_required_end
        config_data += ' and '
      end
      if program.pictures_required_end
        config_data += 'at the end of the trip'
      end
    end
    if program.non_uofm_passengers
      config_data += '<br><br>Non UofM passangers are allowed'
    end
    config_data +=''
    return config_data
  end

  def updated_on_and_by(program)
    return "Updated on " + program.updated_at.strftime('%m/%d/%Y') + " by " + show_user_name_by_id(program.updated_by)
  end

  def number_of_students(program)
    if program.number_of_students.present?
      program.number_of_students.present
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
  
  def render_flash_stream
    turbo_stream.update "flash", partial: "layouts/notification"
  end

end
