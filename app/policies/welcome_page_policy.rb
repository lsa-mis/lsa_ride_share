# frozen_string_literal: true

class WelcomePagePolicy < ApplicationPolicy

  def student?
    is_student? || true
  end

end
