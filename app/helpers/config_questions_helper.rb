module ConfigQuestionsHelper
  def default_config_questions
    [
      "Title - a program with this title will be created after you submit the survey.",
      "Is the program a course? Please answer 'yes' or 'no'. If the program is not a course, no need to enter subject/catalog number/section",
      "Subject (if exist)",
      "Catalog number (if exist)",
      "Section (if exist)",
      "Number of students using ride share",
      "<div>Type of car reservation&nbsp;</div><ul><li>Recurring</li><li>Sporadic</li><li>Events</li><li>Trips</li><li>Other</li></ul>",
      "Does The Course Have A $50 Lab Fee?",
      "<div>What training option would be best for your course? (~30-minutes needed)&nbsp;</div><ul><li>Whole Class In-Person (Recommended)&nbsp;</li><li>Whole Class Via Zoom (Recommended)&nbsp;</li><li>Small Groups Via Zoom&nbsp;</li><li>Individuals Sign Up Online&nbsp;</li><li>Other</li></ul>",
      "If whole class training is possible, what date would be best? (The admin will contact to coordinate time/location)"
    ]
  end
end
