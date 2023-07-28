class SystemReportsController < ApplicationController
  before_action :auth_user
  before_action :set_units, :set_terms

  def index
    @vehicle_reports = VehicleReport.all
    
    authorize :system_report
  end

  def run_report
    @unit_id = params[:unit_id]
    @term_id = params[:term_id]

    @vehicle_reports = VehicleReport.all

    render turbo_stream: turbo_stream.replace(
      :reportListing,
      partial: "system_reports/listing")

    authorize :system_report
  end

  private

    def set_units
      if is_admin?(current_user)
      @units = Unit.where(id: current_user.unit_ids).order(:name)
      elsif is_manager?(current_user)
        manager = Manager.find_by(uniqname: current_user.uniqname)
        @units = Unit.where(id: manager.programs.pluck(:unit_id).uniq).order(:name)
      else
        @units = Unit.all
      end
    end

    def set_terms
      @terms = Term.current_and_future
    end

end
