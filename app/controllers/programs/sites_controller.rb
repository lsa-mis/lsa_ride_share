class Programs::SitesController < SitesController
  before_action :set_site_program
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
    @site_contact = SiteContact.new
    authorize @site
  end

  # GET /sites/1/edit
  def edit
  end

  def edit_program_sites
    @site = Site.new
    @sites = @site_program.sites
    @all_sites = Site.all
    authorize Site
  end

  # POST /sites or /sites.json
  def create
    if params[:site_id].present?
      @site = Site.find(params[:site_id])
      @site_program.sites << @site
      @site = Site.new
      authorize @site
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
    @all_sites = Site.all
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
    # remove site from program, destroy - if the site belongs to no programs
    if @site_program.sites.delete(@site)
      unless @site.programs.present?
        unless @site.destroy
          @site = Site.new
          return
        else
          @site = Site.new
          flash.now[:notice] = "The site was removed from the program"
        end
      else
        @site = Site.new
        flash.now[:notice] = "The site was removed from the program"
      end
    else
      @site = Site.new
      return
    end
  end

  private

    def set_site_program
      @site_program = Program.find(params[:program_id])
      @sites = @site_program.sites
      @all_sites = Site.all
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
      params.require(:site).permit(:title, :address1, :address2, :city, :state, :zip_code)
    end
end
