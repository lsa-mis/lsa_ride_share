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

  def update_answers(params)
    result = { 'success' => true, 'note' => '' }
    params.each do |p|
      if p[0].split("_").first == "item"
        id = p[0].split("_").last
        if id == '1' && strip_tags(p[1]).strip == ''
          result['success'] = false
          result['note'] = "The title is required"
        end
        unless @survey_to_update.find(id).update(answer: p[1])
          result['success'] = false
          result['note'] = "Error updating survey"
          return result
        end
      end
    end
    return result
  end

  def create_program_from_survey(current_user)
    title = ''
    not_course = false
    subject = ''
    catalog_number = ''
    class_section = ''
    number_of_students_using_ride_share = 0
    need_to_create_program = false
    @survey_to_update.each do |s|
      if rich_text_value(s.question).include?("title")
        title = rich_text_no_tags_value(s.answer)
        need_to_create_program = true
      end
      if rich_text_value(s.question).include?("not a course")
        if rich_text_value(s.answer).include?("no")
          not_course = true 
        end
      end
      if rich_text_value(s.question).include?("subject")
        subject = rich_text_no_tags_value(s.answer)
        need_to_create_program = true
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
    if need_to_create_program && (not_course && title.present? || subject.present?)
      program = Program.new(title: title, not_course: not_course, 
                  subject: subject, catalog_number: catalog_number, class_section: class_section, 
                  instructor_attributes: {uniqname: @faculty_survey.uniqname}, 
                  term_id: @faculty_survey.term_id, unit_id: @faculty_survey.unit_id, updated_by: current_user.id, 
                  number_of_students_using_ride_share: number_of_students_using_ride_share,
                  mvr_link: "https://ltp.umich.edu/fleet/vehicle-use/")
      if program.save(validate: false)
        return program.id
      else 
        redirect_to faculty_index_path, alert: "Error creating program from survey"
        return
      end
    else 
      return false
    end
  end

end
