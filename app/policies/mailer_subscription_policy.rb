class MailerSubscriptionPolicy < ApplicationPolicy

  def index?
    true
  end

  def create?
    true
  end

  def new?
    create?
  end

  def update?
    if record.persisted?
      user.id == record.user_id
    else 
      false
    end
  end

  def edit?
    update?
  end

end
