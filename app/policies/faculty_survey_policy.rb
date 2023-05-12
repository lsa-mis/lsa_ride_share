# frozen_string_literal: true

class FacultySurveyPolicy < ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user_in_access_group?
  end

  def faculty_index?
    @user.uniqname == @record[0].uniqname || @user.unit_ids.include?(@record.unit_id)
  end

  def show?
    user_in_access_group?
  end

  def create?
    user_in_access_group?
  end

  def new?
    create?
  end

  def update?
    user_in_access_group?
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

end
