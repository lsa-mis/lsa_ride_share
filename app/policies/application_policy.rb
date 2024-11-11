# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :params, :role, :unit_ids, :record

  def initialize(context, record)
    @user = context[:user]
    @params = context[:params]
    @role = context[:role]
    @unit_ids = context[:unit_ids]
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

  def is_admin?
    # units_all_ids = Unit.all.pluck(:id)
    # @user.unit_ids && (@user.unit_ids & units_all_ids).any?
    @role == "admin"
  end

  def is_super_admin?
    # @user.membership && @user.membership.include?('lsa-was-rails-devs')
    @role == "super_admin"
  end

  def is_student?
    # Student.where(uniqname: user.uniqname, program: Program.current_term).present?
    @role == "student"
  end

  def is_manager?
    # Manager.where(uniqname: user.uniqname).present?
    @role == "manager"
  end

  def user_in_access_group?
    is_admin? || is_super_admin?
  end

end
