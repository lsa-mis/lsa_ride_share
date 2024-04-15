# frozen_string_literal: true

class WelcomePagePolicy < ApplicationPolicy

  def student?
    is_student?
  end

  def manager?
    is_manager?
  end

  def add_phone?
    is_student?
  end

  def edit_phone?
    is_student?
  end

end
