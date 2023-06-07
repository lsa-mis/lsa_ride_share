# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :params, :record

  def initialize(context, record)
    @user = context[:user]
    @params = context[:params]
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

  def get_instructor_id?
    user_in_access_group?
  end

  def unit_admin?
    units_all_ids = Unit.all.pluck(:id)
    @user.unit_ids && (@user.unit_ids & units_all_ids).any?
  end

  def user_admin?
    @user.membership && @user.membership.include?('lsa-was-rails-devs')
  end

  def user_in_access_group?
    unit_admin? || user_admin?
  end

end
