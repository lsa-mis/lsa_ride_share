class Programs::SitesController < SitesController
  before_action :set_site_program
  before_action :set_site, only: %i[ edit destroy ]
  before_action :set_units

  # GET /sites/new
  def new
    @site = Site.new
    authorize @site
  end

  # GET /sites/1/edit
  def edit
    session[:return_to] = request.referer
  end

  def edit_program_sites
    @site = Site.new
    authorize Site
  end

  # POST /sites or /sites.json
  def create
    if params[:site_id].present?
      @site = Site.find(params[:site_id])
      authorize @site
      if @site_program.sites << @site
        @site = Site.new
        flash.now[:notice] = "The site was added"
      end
    else
     @site = Site.new(site_params)
     authorize @site
      if @site.save
        @site_program.sites << @site
        @site = Site.new
        flash.now[:notice] = "The site was added"
      end
    end
    @sites = @site_program.sites
    @all_sites = Site.all - @sites
  end

  # DELETE /sites/1 or /sites/1.json
  def destroy
    # remove site from program, don't destroy
    if @site_program.sites.delete(@site)
      flash.now[:notice] = "The site was removed from the program"
    end
    @site = Site.new
  end

  private

    def set_site_program
      @site_program = Program.find(params[:program_id])
      @sites = @site_program.sites
      @all_sites = Site.all - @sites
    end

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
      params.require(:site).permit(:title, :address1, :address2, :city, :state, :zip_code, :unit_id)
    end
end
