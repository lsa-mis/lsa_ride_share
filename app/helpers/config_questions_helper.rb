module ConfigQuestionsHelper
  def default_config_questions
    [
      "What is the Title of your program? This will be used as the program title in RideShare.",
      "Is this program a course? Yes or No. If the program is a course, please enter subject, catalog number and section. If the program has more than one associated course, you'll be able to add them on the program page after submitting the survey.",
      "Subject (if exist)",
      "Catalog number (if exist)",
      "Section (if exist)",
      "Number of students using RideShare",
      "<div>Type of car reservation&nbsp;</div><ul><li>Recurring</li><li>Sporadic</li><li>Events</li><li>Trips</li><li>Other</li></ul>",
      "Does The Course Have A $50 Lab Fee?",
      "<div>What training option would be best for your course? (~30-minutes needed)&nbsp;</div><ul><li>Whole Class In-Person (Recommended)&nbsp;</li><li>Whole Class Via Zoom (Recommended)&nbsp;</li><li>Small Groups Via Zoom&nbsp;</li><li>Individuals Sign Up Online&nbsp;</li><li>Other</li></ul>",
      "If whole class training is possible, what date would be best? (The admin will contact to coordinate time/location)",
      "Additional comments. (Add section numbers here if the program has more than one section.)"
    ]
  end
end
