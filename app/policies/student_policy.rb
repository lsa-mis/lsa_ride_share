# frozen_string_literal: true

class StudentPolicy < ApplicationPolicy

  def index?
    return true if user_in_access_group? 
    return true if is_program_manager?
    return false
  end

  def show?
    user_in_access_group?
  end

  def update_student_list?
    return true if user_in_access_group? 
    return true if is_instructor?
    return false
  end

  def add_students?
    return true if user_in_access_group? 
    return true if is_instructor?
    return false
  end

  def create?
    return true if user_in_access_group? 
    return true if is_instructor?
    return false
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

  # def canvas_results?
  #   user_in_access_group?
  # end

  # def student_canvas_result?
  #   user_in_access_group?
  # end

  def destroy?
    return true if user_in_access_group? 
    return true if is_instructor?
    return false
  end

  private

  def is_program_manager?
    program = Program.find(params[:program_id])
    program.all_managers.include?(@user.uniqname)
  end

  def is_instructor?
    program = Program.find(params[:program_id])
    program.instructor.uniqname == @user.uniqname
  end

end
