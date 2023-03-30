class Cars::NotesController < ApplicationController
  include Noteable

  before_action :set_noteable

  private

    def set_noteable
      @noteable = Car.find(params[:car_id])
    end
end
