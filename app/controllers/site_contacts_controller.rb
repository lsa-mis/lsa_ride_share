class SiteContactsController < ApplicationController
  before_action :set_site_contact, only: %i[ show edit update destroy ]

  # GET /site_contacts or /site_contacts.json
  # def index
  #   @site_contacts = SiteContact.all
  #   authorize @site_contacts
  # end

  # # GET /site_contacts/1 or /site_contacts/1.json
  # def show
  # end

  # # GET /site_contacts/new
  # def new
  #   @site_contact = SiteContact.new
  #   authorize @site_contact
  # end

  # # GET /site_contacts/1/edit
  # def edit
  # end

  # # POST /site_contacts or /site_contacts.json
  # def create
  #   @site_contact = SiteContact.new(site_contact_params)

  #   respond_to do |format|
  #     if @site_contact.save
  #       format.html { redirect_to site_contact_url(@site_contact), notice: "Site contact was successfully created." }
  #       format.json { render :show, status: :created, location: @site_contact }
  #     else
  #       format.html { render :new, status: :unprocessable_entity }
  #       format.json { render json: @site_contact.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # # PATCH/PUT /site_contacts/1 or /site_contacts/1.json
  # def update
  #   respond_to do |format|
  #     if @site_contact.update(site_contact_params)
  #       format.html { redirect_to site_contact_url(@site_contact), notice: "Site contact was successfully updated." }
  #       format.json { render :show, status: :ok, location: @site_contact }
  #     else
  #       format.html { render :edit, status: :unprocessable_entity }
  #       format.json { render json: @site_contact.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # # DELETE /site_contacts/1 or /site_contacts/1.json
  # def destroy
  #   @site_contact.destroy

  #   respond_to do |format|
  #     format.html { redirect_to site_contacts_url, notice: "Site contact was successfully destroyed." }
  #     format.json { head :no_content }
  #   end
  # end

  # private
  #   # Use callbacks to share common setup or constraints between actions.
  #   def set_site_contact
  #     @site_contact = SiteContact.find(params[:id])
  #     authorize @site_contact
  #   end

  #   # Only allow a list of trusted parameters through.
  #   def site_contact_params
  #     params.require(:site_contact).permit(:title, :first_name, :last_name, :phone_number, :email)
  #   end
end
