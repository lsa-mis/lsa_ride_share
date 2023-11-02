# frozen_string_literal: true

class ProgramPolicy < ApplicationPolicy

  def index?
    user_in_access_group? || is_manager?
  end

  def show?
    user_in_access_group? || is_program_manager?
  end

  def create?
    user_in_access_group?
  end

  def new?
    create?
  end

  def update?
    user_in_access_group? || is_instructor?
  end

  def edit?
    update?
  end

  def duplicate?
    update?
  end

  def destroy?
    false
  end

  def get_programs_list?
    create?
  end

  def get_students_list?
    create?
  end

  def get_sites_list?
    create?
  end

  def is_manager?
    Program.all.map { |p| p.all_managers.include?(@user.uniqname) }.any?
  end

  def is_program_manager?
    program = Program.find(params[:id])
    program.all_managers.include?(@user.uniqname)
  end

  def is_instructor?
    program = Program.find(params[:id])
    program.instructor.uniqname == @user.uniqname
  end

end
