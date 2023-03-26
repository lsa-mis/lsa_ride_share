# frozen_string_literal: true

class StudentPolicy < ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user_in_access_group?
  end

  def show?
    user_in_access_group?
  end

  def update_student_list?
    user_in_access_group?
  end

  def add_students?
    user_in_access_group?
  end

  def update_mvr_status?
    user_in_access_group?
  end

  def canvas_results?
    user_in_access_group?
  end

end
