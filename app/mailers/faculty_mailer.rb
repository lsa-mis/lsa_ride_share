class FacultyMailer < ApplicationMailer
  before_action :set_faculty_survey

  def send_faculty_survey
    @recipient = @faculty_survey.uniqname + '@umich.edu'
    mail(to: @recipient, subject: "RideShare program: please fill out the survey")
    create_email_log_records(email_type: "send_faculty_survey")
  end

  def faculty_survey_program_created
    mail(to: @unit_email, subject: "RideShare program: new program created from faculty survey")
    create_email_log_records(email_type: "faculty_survey_program_created")
  end

  def faculty_survey_confirmation
    @recipient = @faculty_survey.uniqname + '@umich.edu'
    mail(to: @recipient, subject: "RideShare program: faculty survey submitted")
    create_email_log_records(email_type: "faculty_survey_confirmation")
  end

  private 

  def set_faculty_survey
    @faculty_survey = params[:faculty_survey]
    @contact_phone = @faculty_survey.unit.unit_preferences.find_by(name: "contact_phone").value.presence || ""
    @unit_email = @faculty_survey.unit.unit_preferences.find_by(name: "notification_email").value.presence || "lsa-rideshare-admins@umich.edu"
  end

  def create_email_log_records(sent_from_model:, email_type:)
    EmailLog.create(sent_from_model: "FacultySurvey", record_id: @faculty_survey.id, email_type: email_type,
      sent_to: @recipient, sent_by: params[:user].id, sent_at: DateTime.now)
  end
end
