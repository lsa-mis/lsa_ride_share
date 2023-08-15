class AdminMailer < ApplicationMailer
  def test
    # if Rails env is development, use current_user, otherwise use a dummy user
    if Rails.env.development? || Rails.env.staging?
      @user = User.first
    else
      @user = current_user
    end

    @url = 'https://rideshare.lsa.umich.edu/'
    mail(to: @user.email, subject: 'Testing the Admin Mailer')
  end
end
