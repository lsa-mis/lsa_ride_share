# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def unit_admin?
    # access_groups = ['lsa-rideshare-admins']
    # user.membership && (user.membership & access_groups).any?
    units = Unit.all.pluck(:id)
    # user.unit && units.include?(user.unit)
    user.unit && (user.unit & units).any?
  end

  def user_admin?
    user.membership && user.membership.include?('lsa-rideshare-admins')
  end

  def user_in_access_group?
    unit_admin? || user_admin?
  end

end
