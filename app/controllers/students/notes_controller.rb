class Students::NotesController < ApplicationController
  include Noteable

  before_action :set_noteable

  private

    def set_noteable
      @noteable = Student.find(params[:student_id])
    end
end
