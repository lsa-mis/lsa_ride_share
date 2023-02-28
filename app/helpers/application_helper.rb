module ApplicationHelper

  def term_codes
    [
      ["Fall 2022", "2410"],
      ["Winter 2023", "2420"],
      ["Spring 2023", "2430"],
      ["Spring/Summer 2023", "2440"],
      ["Summer 2023", "2450"],
      ["Fall 2023", "2460"],
      ["Winter 2024", "2470"],
      ["Spring 2024", "2480"],
      ["Spring/Summer 2024", "2490"],
      ["Summer 2024", "2500"],
      ["Fall 2024", "2510"],
      ["Winter 2025", "2520"],
      ["Spring 2025", "2530"],
      ["Spring/Summer 2025", "2540"],
      ["Summer 2025", "2550"],
      ["Fall 2025", "2560"],
      ["Winter 2026", "2570"],
      ["Spring 2026", "2580"]
    ]
  end

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
    User.find(id).email
  end

end
