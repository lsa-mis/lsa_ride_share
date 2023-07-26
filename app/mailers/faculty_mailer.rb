class FacultyMailer < ApplicationMailer
  before_action :set_faculty_survey, only: [:send_faculty_survey_email, :faculty_survey_program_created, :faculty_survey_confirmation]

  def send_faculty_survey_email(user)
    @recipient = @faculty_survey.uniqname + '@umich.edu'
    mail(to: @recipient, subject: "RideShare program: plaese fill out the survey" )
    EmailLog.create(sent_from_model: "FacultySurvey", record_id: @faculty_survey.id, email_type: "send_faculty_survey_email",
      sent_to: @recipient, sent_by: user.id, sent_at: DateTime.now)
  end

  def faculty_survey_program_created(user)
    mail(to: @unit_email, subject: "RideShare program: new program created from faculty survey" )
    EmailLog.create(sent_from_model: "FacultySurvey", record_id: @faculty_survey.id, email_type: "faculty_survey_program_created",
      sent_to: @unit_email, sent_by: user.id, sent_at: DateTime.now)
  end

  def faculty_survey_confirmation(user)
    @recipient = @faculty_survey.uniqname + '@umich.edu'
    mail(to: @recipient, subject: "RideShare program: faculty survey submitted" )
    EmailLog.create(sent_from_model: "FacultySurvey", record_id: @faculty_survey.id, email_type: "faculty_survey_confirmation",
      sent_to: @recipient, sent_by: user.id, sent_at: DateTime.now)
  end

  private 

  def set_faculty_survey
    @faculty_survey = params[:faculty_survey]
    @contact_phone = @faculty_survey.unit.unit_preferences.find_by(name: "contact_phone").value.presence || ""
    @unit_email = @faculty_survey.unit.unit_preferences.find_by(name: "notification_email").value.presence || "lsa-rideshare-admins@umich.edu"
  end

end
