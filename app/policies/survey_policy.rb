# frozen_string_literal: true

class SurveyPolicy < ApplicationPolicy

  def survey?
    @user.uniqname == @record.uniqname
  end

  def save_survey?
    @user.uniqname == @record.uniqname
  end

end
