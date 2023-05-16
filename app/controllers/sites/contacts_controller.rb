class Sites::ContactsController < ApplicationController
  before_action :auth_user
  before_action :set_site
  before_action :set_contact, only: %i[ show edit update destroy ]

  # GET /contacts or /contacts.json
  def index
    @contacts = @site.contacts
    @contact = Contact.new
    authorize @contacts
  end

  # GET /contacts/1 or /contacts/1.json
  def show
  end

  # GET /contacts/new
  def new
    @contact = Contact.new
    authorize @contact
  end

  # GET /contacts/1/edit
  def edit
  end

  # POST /contacts or /contacts.json
  def create
    @contact = Contact.new(contact_params)
    @contact.site_id = @site.id
    authorize @contact
    if @contact.save
      @contact = Contact.new
      flash.now[:notice] = "Contact list is updated"
    end
    @contacts = @site.contacts
  end

  # PATCH/PUT /contacts/1 or /contacts/1.json
  def update
    if @contact.update(contact_params)
      @contact = Contact.new
      @contacts = @site.contacts
      redirect_to site_contacts_path(@site), notice: "Contact was successfully updated." 
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /contacts/1 or /contacts/1.json
  def destroy
    if @contact.destroy
      @contacts = @site.contacts
      @contact = Contact.new
      flash.now[:notice] = "Contact is removed"
    else
      @contacts = @site.contacts
      render :index, status: :unprocessable_entity
    end

  end

  private

    def set_site
      @site = Site.find(params[:site_id])
    end
      
    def set_contact
      @contact = Contact.find(params[:id])
      authorize @contact
    end

    # Only allow a list of trusted parameters through.
    def contact_params
      params.require(:contact).permit(:title, :first_name, :last_name, :phone_number, :email)
    end
end
