# frozen_string_literal: true

class SurveyPolicy < ApplicationPolicy
  attr_reader :user, :survey

  def initialize(user, survey)
    @user = user
    @survey = survey
  end

  def survey?
    @user.uniqname == @survey.uniqname
  end

  def save_survey?
    @user.uniqname == @survey.uniqname
  end


end
