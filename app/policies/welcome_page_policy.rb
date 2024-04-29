# frozen_string_literal: true

class WelcomePagePolicy < ApplicationPolicy

  def student?
    is_student?
  end

  def manager?
    is_manager?
  end

  def add_student_phone?
    is_student?
  end

  def edit_student_phone?
    is_student?
  end

  def add_manager_phone?
    is_manager?
  end

  def edit_manager_phone?
    is_manager?
  end

end
