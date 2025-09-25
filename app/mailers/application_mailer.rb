class ApplicationMailer < ActionMailer::Base
  include ApplicationHelper
  prepend_view_path "app/views/mailers"
  default from: "no-reply@rideshare.lsa.umich.edu",
          to: "lsa-rideshare-admins@umich.edu",
          subject: "Mail from the LSA Rideshare App"
  layout "mailer"

  protected

  def mail(headers = {})
    headers[:reply_to] ||= reply_to_email
    super(headers)
  end

  private

  def reply_to_email
    unit = params[:reservation]&.program.unit
    if unit.present?
      email = UnitPreference.find_by(name: "notification_email", unit_id: unit.id)&.value
      return email if email.present?
    end
    'lsa-rideshare-admins@umich.edu'
  end

end
