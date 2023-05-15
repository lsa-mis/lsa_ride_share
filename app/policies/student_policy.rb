# frozen_string_literal: true

class StudentPolicy < ApplicationPolicy

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

  def create?
    user_in_access_group?
  end

  def new?
    create?
  end

  def update_mvr_status?
    user_in_access_group?
  end

  def canvas_results?
    user_in_access_group?
  end

  def destroy?
    user_in_access_group?
  end

end
