# frozen_string_literal: true

class Program::CoursePolicy < ApplicationPolicy

  def index?
    user_in_access_group?
  end

  def create?
    user_in_access_group? || is_program_instructor?
  end

  def new?
    create?
  end

  def update?
    user_in_access_group? || is_program_instructor?
  end

  def edit?
    update?
  end

  def edit_program_sites?
    user_in_access_group? || is_program_instructor?
  end

  def destroy?
    user_in_access_group? || is_program_instructor?
  end

  def is_program_instructor?
    Program.find(@params[:program_id]).instructor == Manager.find_by(uniqname: @user.uniqname)
  end

end
