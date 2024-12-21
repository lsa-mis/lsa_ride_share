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

  private
  
  def is_admin?
    @role == "admin"
  end

  def is_super_admin?
    @role == "super_admin"
  end

  def is_student?
    @role == "student"
  end

  def is_manager?
    @role == "manager"
  end

  def user_in_access_group?
    is_admin? || is_super_admin?
  end

end
