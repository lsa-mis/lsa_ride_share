class Sites::SiteContactsController < ApplicationController
  before_action :set_site
  before_action :set_site_contact, only: %i[ show edit update destroy ]

  # GET /site_contacts or /site_contacts.json
  def index
    @site_contacts = @site.site_contacts
    @site_contact = SiteContact.new
    authorize @site_contacts
  end

  # GET /site_contacts/1 or /site_contacts/1.json
  def show
  end

  # GET /site_contacts/new
  def new
    @site_contact = SiteContact.new
    authorize @site_contact
  end

  # GET /site_contacts/1/edit
  def edit
  end

  # POST /site_contacts or /site_contacts.json
  def create
    @site_contact = SiteContact.new(site_contact_params)
    @site_contact.site_id = @site.id
    authorize @site_contact
    if @site_contact.save
      @site_contact = SiteContact.new
      flash.now[:notice] = "Contact list is updated"
    end
    @site_contacts = @site.site_contacts
  end

  # PATCH/PUT /site_contacts/1 or /site_contacts/1.json
  def update
    if @site_contact.update(site_contact_params)
      @site_contact = SiteContact.new
      @site_contacts = @site.site_contacts
      redirect_to site_site_contacts_path(@site), notice: "Contact was successfully updated." 
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /site_contacts/1 or /site_contacts/1.json
  def destroy
    if @site_contact.destroy
      @site_contacts = @site.site_contacts
      @site_contact = SiteContact.new
      flash.now[:notice] = "Contact is removed"
    else
      @site_contacts = @site.site_contacts
      render :index, status: :unprocessable_entity
    end

  end

  private

    def set_site
      @site = Site.find(params[:site_id])
    end
      
    def set_site_contact
      @site_contact = SiteContact.find(params[:id])
      authorize @site_contact
    end

    # Only allow a list of trusted parameters through.
    def site_contact_params
      params.require(:site_contact).permit(:title, :first_name, :last_name, :phone_number, :email)
    end
end
