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
