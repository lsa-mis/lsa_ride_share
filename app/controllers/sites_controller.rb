class SitesController < ApplicationController
  before_action :set_site, only: %i[ show edit update destroy ]
  before_action :set_units

  # GET /sites or /sites.json
  def index
    if params[:unit_id].present?
      @sites = Site.includes(:programs).where(programs: { id: Program.where(unit_id: params[:unit_id]) })
    else
      @sites = Site.includes(:programs).where(programs: { id: Program.where(unit_id: @units) })
    end
    authorize @sites
  end

  # GET /sites/1 or /sites/1.json
  def show
    @programs = @site.programs
    @site_contacts = @site.site_contacts
  end

  # GET /sites/new
  def new
    @site = Site.new
    authorize @site
  end

  # GET /sites/1/edit
  def edit
  end

  # POST /sites or /sites.json
  def create
    if params[:site_id].present?
      @site = Site.find(params[:site_id])
    else
     @site = Site.new(site_params)
    end

    respond_to do |format|
      if @site.save
        # @site_program.sites << @site
        format.turbo_stream { redirect_to @site_program, 
                              notice: "The site was added" 
                            }
      else
        format.turbo_stream { redirect_to @site_program, 
          alert: "Fail: you need to enter a site data" 
        }
      end
    end

  end

  # PATCH/PUT /sites/1 or /sites/1.json
  def update
    respond_to do |format|
      if @site.update(site_params)
        format.html { redirect_to site_url(@site), notice: "Site was successfully updated." }
        format.json { render :show, status: :ok, location: @site }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @site.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sites/1 or /sites/1.json
  def destroy
    @site.destroy

    respond_to do |format|
      format.html { redirect_to sites_url, notice: "Site was successfully destroyed." }
      format.json { head :no_content }
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
      params.require(:site).permit(:title, :address1, :address2, :city, :state, :zip_code)
    end
end
