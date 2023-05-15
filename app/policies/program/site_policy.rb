# frozen_string_literal: true

class Program::SitePolicy < ApplicationPolicy

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

  def remove_site_from_program?
    user_in_access_group? || is_program_instructor?
  end

  def is_program_instructor?
    Program.find(@program_id).instructor == Manager.find_by(uniqname: @user.uniqname)
  end

end
