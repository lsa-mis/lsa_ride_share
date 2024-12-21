class SitesController < ApplicationController
  before_action :auth_user
  before_action :set_site, only: %i[ show edit update destroy ]
  before_action :set_units

  # GET /sites or /sites.json
  def index
    if params[:unit_id].present?
      @sites = Site.where(unit_id: params[:unit_id]).order(:title)
    else
      @sites = Site.where(unit_id: session[:unit_ids]).order(:title)
    end
    authorize @sites
  end

  # GET /sites/1 or /sites/1.json
  def show
    @programs = @site.programs.order(:title, :catalog_number, :class_section)
    @contacts = @site.contacts
  end

  # GET /sites/1/edit
  def edit
    session[:return_to] = request.referer
  end

  # PATCH/PUT /sites/1 or /sites/1.json
  def update
    if @site.update(site_params)
      redirect_back_or_default("The site was updated.", false, sites_url)
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_site
      @site = Site.find(params[:id])
      authorize @site
    end

    def set_units
      @units = Unit.where(id: session[:unit_ids]).order(:name)
    end

    # Only allow a list of trusted parameters through.
    def site_params
      params.require(:site).permit(:title, :address1, :address2, :city, :state, :zip_code, :updated_by)
    end
end
