# frozen_string_literal: true

class WelcomePagePolicy < ApplicationPolicy

  def student?
    is_student?
  end

  def manager?
    is_manager?
  end

end
