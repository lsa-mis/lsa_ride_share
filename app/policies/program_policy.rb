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

  def program_data?
    update?
  end

  def destroy?
    false
  end

  def is_manager?
    Program.all.map { |p| p.all_managers.include?(@user.uniqname) }.any?
  end

  def is_program_manager?
    @record.all_managers.include?(@user.uniqname)
  end

  def is_instructor?
    @record.instructor.uniqname == @user.uniqname
  end

end
