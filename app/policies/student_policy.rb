# frozen_string_literal: true

class StudentPolicy < ApplicationPolicy

  def index?
    user_in_access_group? || is_program_manager?
  end

  def show?
    user_in_access_group?
  end

  def update_student_list?
    user_in_access_group? || is_instructor?
  end

  def add_students?
    user_in_access_group? || is_instructor?
  end

  def create?
    user_in_access_group? || is_instructor?
  end

  def new?
    create?
  end

  def edit?
    update?
  end

  def update?
    user_in_access_group?
  end

  def update_mvr_status?
    user_in_access_group?
  end

  def update_student_mvr_status?
    user_in_access_group?
  end

  def canvas_results?
    user_in_access_group?
  end

  def student_canvas_result?
    user_in_access_group?
  end

  def destroy?
    user_in_access_group? || is_instructor?
  end

  def is_program_manager?
    program = Program.find(params[:program_id])
    program.all_managers.include?(@user.uniqname)
  end

  def is_instructor?
    program = Program.find(params[:program_id])
    program.instructor.uniqname == @user.uniqname
  end

end
