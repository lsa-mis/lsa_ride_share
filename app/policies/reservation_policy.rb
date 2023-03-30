# frozen_string_literal: true

class ReservationPolicy < ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def show?
    user_in_access_group?
  end

end
