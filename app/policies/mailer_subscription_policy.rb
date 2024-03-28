class MailerSubscriptionPolicy < ApplicationPolicy

  def index?
    true
  end

  def create?
    true
  end

  def update?
    create?
  end

end
