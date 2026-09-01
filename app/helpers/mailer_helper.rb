module MailerHelper
  def subscribed?(mailer:, driver:, user: nil, subscriptions: nil)
    user ||= User.find_by(uniqname: driver.uniqname)
    return true unless user.present?

    subscription = if subscriptions.present?
      subscriptions[[mailer, user.id]]
    else
      MailerSubscription.find_by(mailer: mailer, user_id: user.id)
    end

    subscription.nil? || !subscription.unsubscribed
  end

  def reminders_on?(program_id: nil, unit_id: nil)
    if program_id.present?
      unit_id = Program.find(program_id).unit.id
    end
    return false unless unit_id.present?
    return UnitPreference.find_by(unit_id: unit_id, name: "send_reminders").on_off
  end

  def is_checked?(subscription)
    if subscription
      return ""
    else 
      return "checked"
    end
  end
end
