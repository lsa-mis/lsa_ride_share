module MailerHelper
  def subscribed?(mailer:, driver:)
    if MailerSubscription.find_by(mailer: mailer, user_id: User.find_by(uniqname: driver.uniqname)).present?
      if MailerSubscription.find_by(mailer: mailer, user_id: User.find_by(uniqname: driver.uniqname).id).unsubscribed
        return false
      else 
        return true
      end
    else
      return true
    end
  end
end
