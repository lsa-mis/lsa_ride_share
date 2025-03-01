class Programs::SitesController < SitesController
  before_action :auth_user
  before_action :set_site_program
  before_action :set_site, only: %i[ edit remove_site_from_program ]
  before_action :set_units

  # GET /sites/new
  def new
    @site = Site.new
    authorize([@site_program, @site]) 
  end

  # GET /sites/1/edit
  def edit
    session[:return_to] = request.referer
  end

  def edit_program_sites
    @site = Site.new
    authorize([@site_program, @site]) 
  end

  # POST /sites or /sites.json
  def create
    if params[:site_id].present?
      @site = Site.find(params[:site_id])
      authorize([@site_program, @site]) 
      if @site_program.sites << @site
        @site = Site.new
        flash.now[:notice] = "The site was added."
      end
    else
     @site = Site.new(site_params)
     authorize([@site_program, @site]) 
      if @site.save
        @site_program.sites << @site
        @site = Site.new
        flash.now[:notice] = "The site was added."
      end
    end
  end

  # DELETE /sites/1 or /sites/1.json
  def remove_site_from_program
    if @site_program.sites.delete(@site)
      flash.now[:notice] = "The site was removed from the program."
    end
    @site = Site.new
  end

  private

    def set_site_program
      @site_program = Program.find(params[:program_id])
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_site
      @site = Site.find(params[:id])
      authorize([@site_program, @site]) 
    end

    def set_units
      @units = Unit.where(id: session[:unit_ids]).order(:name)
    end

    # Only allow a list of trusted parameters through.
    def site_params
      params.require(:site).permit(:title, :address1, :address2, :city, :state, :zip_code, :unit_id, :updated_by)
    end
end
