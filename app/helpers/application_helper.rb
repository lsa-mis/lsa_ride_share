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
