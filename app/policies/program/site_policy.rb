# frozen_string_literal: true

class Program::SitePolicy < ApplicationPolicy

  def create?
    return true if user_in_access_group? 
    return true if is_program_instructor?
    return false
  end

  def new?
    create?
  end

  def update?
    create?
  end

  def edit?
    update?
  end

  def edit_program_sites?
    create?
  end

  def remove_site_from_program?
    create?
  end

  def is_program_instructor?
    Program.find(@params[:program_id]).instructor == Manager.find_by(uniqname: @user.uniqname)
  end

end
