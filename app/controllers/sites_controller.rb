class SitesController < ApplicationController
  before_action :set_site, only: %i[ show edit update destroy ]
  before_action :set_units

  # GET /sites or /sites.json
  def index
    if params[:unit_id].present?
      @sites = Site.where(unit_id: params[:unit_id])
    else
      @sites = Site.where(unit_id: current_user.unit)
    end
    authorize @sites
  end

  # GET /sites/1 or /sites/1.json
  def show
    @programs = @site.programs
    @site_contacts = @site.site_contacts
  end

  # GET /sites/1/edit
  def edit
    session[:return_to] = request.referer
  end

  # PATCH/PUT /sites/1 or /sites/1.json
  def update
    if @site.update(site_params)
      redirect_back_or_default("The site was updated", sites_url)
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_site
      @site = Site.find(params[:id])
      authorize @site
    end

    def set_units
      @units = Unit.where(id: current_user.unit).order(:name)
    end

    # Only allow a list of trusted parameters through.
    def site_params
      params.require(:site).permit(:title, :address1, :address2, :city, :state, :zip_code, :updated_by)
    end
end
