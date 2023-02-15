class AdminAccessesController < ApplicationController
  before_action :set_admin_access, only: %i[ show edit update destroy ]

  # GET /admin_accesses or /admin_accesses.json
  def index
    @admin_accesses = AdminAccess.all
  end

  # GET /admin_accesses/1 or /admin_accesses/1.json
  def show
  end

  # GET /admin_accesses/new
  def new
    @admin_access = AdminAccess.new
  end

  # GET /admin_accesses/1/edit
  def edit
  end

  # POST /admin_accesses or /admin_accesses.json
  def create
    @admin_access = AdminAccess.new(admin_access_params)

    respond_to do |format|
      if @admin_access.save
        format.html { redirect_to admin_access_url(@admin_access), notice: "Admin access was successfully created." }
        format.json { render :show, status: :created, location: @admin_access }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @admin_access.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin_accesses/1 or /admin_accesses/1.json
  def update
    respond_to do |format|
      if @admin_access.update(admin_access_params)
        format.html { redirect_to admin_access_url(@admin_access), notice: "Admin access was successfully updated." }
        format.json { render :show, status: :ok, location: @admin_access }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @admin_access.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin_accesses/1 or /admin_accesses/1.json
  def destroy
    @admin_access.destroy

    respond_to do |format|
      format.html { redirect_to admin_accesses_url, notice: "Admin access was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admin_access
      @admin_access = AdminAccess.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def admin_access_params
      params.require(:admin_access).permit(:department, :ldap_group)
    end
end
