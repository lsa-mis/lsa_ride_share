class VehicleReports::NotesController < ApplicationController
  include Noteable

  before_action :set_noteable

  private

    def set_noteable
      @noteable = VehicleReport.find(params[:vehicle_report_id])
    end
end
