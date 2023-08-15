class Sites::NotesController < ApplicationController
  include Noteable
  before_action :auth_user
  before_action :set_noteable

  private

    def set_noteable
      @noteable = Site.find(params[:site_id])
    end
end
