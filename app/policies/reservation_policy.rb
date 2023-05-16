# frozen_string_literal: true

class ReservationPolicy < ApplicationPolicy

  def show?
    user_in_access_group?
  end

end
