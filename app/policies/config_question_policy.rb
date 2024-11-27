# frozen_string_literal: true

class ConfigQuestionPolicy < ApplicationPolicy

  def index?
    @user.uniqname == FacultySurvey.find(@record[0].faculty_survey_id).uniqname || (@unit_ids&.include?(FacultySurvey.find(@record[0].faculty_survey_id).unit_id) && user_in_access_group?)
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
    user_in_access_group?
  end

end
