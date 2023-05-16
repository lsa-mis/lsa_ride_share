class Survey
  include ActionView::Helpers::SanitizeHelper
  include ApplicationHelper

  def initialize(faculty_survey)
    @faculty_survey = faculty_survey
    @survey_to_update = @faculty_survey.config_questions.order(:id)
  end

  def uniqname
    @faculty_survey.uniqname
  end

  def unit_id
    @faculty_survey.unit_id
  end

  def questions_to_display
    if @faculty_survey.program_id.present?
      survey = []
      @survey_to_update.each do |item|
        unless rich_text_value(item.question).include?("title") ||
              rich_text_value(item.question).include?("not a course") ||
              rich_text_value(item.question).include?("subject") ||
              rich_text_value(item.question).include?("catalog") ||
              rich_text_value(item.question).include?("section") ||
              rich_text_value(item.question).include?("number of students using ride share") 
          survey << item
        end
      end
    else
      survey = @faculty_survey.config_questions.order(:id)
    end
    return survey
  end

  def has_answers?
    rich_text_no_tags_value(@survey_to_update[0].answer).present?
  end

  def update_answers(params)
    result = { 'success' => true, 'note' => '' }
    course = false
    # answers have rich_text format and params are something like this:
    # {"item_17_1"=>"<ul><li>Events</li></ul><div><br></div>", 
    # "item_18_2"=>"<div>no</div>", 
    # "item_19_3"=>"<ul><li>Small Groups Via Zoom&nbsp;</li></ul><div><br></div>",
    # "item_20_4"=>"<div>Monday</div>"}
    #
    # first two or five answers are required
    #  
    params.each do |p|
      if p[0].split("_").first == "item"
        question_number = p[0].split("_").last
        question_id = p[0].split("_").second
        if question_number == '1' 
          if strip_tags(p[1]).strip == ''
            result['success'] = false
            result['note'] = "The title is required. "
          else
            title = strip_tags(p[1]).strip
            if Program.find_by(title: title, term_id: @faculty_survey.term_id).present?
              result['success'] = false
              result['note'] = "A program with this title exist for term #{@faculty_survey.term.name}. "
            end
          end
        end
        if question_number == '2'
          if strip_tags(p[1]).strip == ''
            result['success'] = false
            result['note'] += "Is the program a course? The answer is required. "
          else
            course = true if p[1].downcase.include?("yes")
          end
        end
        if course && strip_tags(p[1]).strip == ''
          case question_number
          when '3'
            result['success'] = false
            result['note'] += "Subject is required. "
          when '4'
            result['success'] = false
            result['note'] += "Catalog number is required. "
          when '5'
            result['success'] = false
            result['note'] += "Section is required. "
          end
        end
        unless @survey_to_update.find(question_id).update(answer: p[1])
          result['success'] = false
          result['note'] = "Error updating survey"
          return result
        end
      end
    end
    return result
  end

  def create_program_from_survey(current_user)
    not_course = false
    title = ''
    subject = ''
    catalog_number = ''
    class_section = ''
    number_of_students_using_ride_share = 0
    @survey_to_update.each do |s|
      if rich_text_value(s.question).include?("title")
        title = rich_text_no_tags_value(s.answer)
      end
      if rich_text_value(s.question).include?("not a course")
        if rich_text_value(s.answer).include?("no")
          not_course = true 
        end
      end
      if rich_text_value(s.question).include?("subject")
        subject = rich_text_no_tags_value(s.answer)
      end
      if rich_text_value(s.question).include?("catalog")
        catalog_number = rich_text_no_tags_value(s.answer)
      end
      if rich_text_value(s.question).include?("section")
        class_section = rich_text_no_tags_value(s.answer)
      end
      if rich_text_value(s.question).include?("number of students using ride share")
        number_of_students_using_ride_share = rich_text_no_tags_value(s.answer).to_i
      end
    end
    if Manager.find_by(uniqname: @faculty_survey.uniqname).present?
      instructor = Manager.find_by(uniqname: @faculty_survey.uniqname)
    else
      instructor = Manager.create(uniqname: @faculty_survey.uniqname, first_name: @faculty_survey.first_name, last_name: @faculty_survey.last_name)
    end
    program = Program.new(title: title, not_course: not_course, 
                subject: subject, catalog_number: catalog_number, class_section: class_section, 
                instructor_id: instructor.id, 
                term_id: @faculty_survey.term_id, unit_id: @faculty_survey.unit_id, updated_by: current_user.id, 
                number_of_students_using_ride_share: number_of_students_using_ride_share,
                mvr_link: "https://ltp.umich.edu/fleet/vehicle-use/")
    if program.save(validate: false)
      instructor.update(program_id: program.id)
      return program.id
    else 
      return false
    end
  end

end
