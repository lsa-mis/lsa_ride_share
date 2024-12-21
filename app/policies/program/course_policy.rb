# frozen_string_literal: true

class Program::CoursePolicy < ApplicationPolicy

  def index?
    return true if user_in_access_group? 
    return true if is_program_instructor?
    return false
  end

  def create?
    return true if user_in_access_group? 
    return true if is_program_instructor?
    return false
  end

  def new?
    create?
  end

  def update?
    return true if user_in_access_group? 
    return true if is_program_instructor?
    return false
  end

  def edit?
    update?
  end

  def destroy?
    return true if user_in_access_group? 
    return true if is_program_instructor?
    return false
  end

  private

  def is_program_instructor?
    Program.find(@params[:program_id]).instructor == Manager.find_by(uniqname: @user.uniqname)
  end

end
