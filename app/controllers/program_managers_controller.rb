class ProgramManagersController < ApplicationController
  before_action :set_program_manager, only: %i[ show edit update destroy ]

  # GET /program_managers or /program_managers.json
  def index
    @program_managers = ProgramManager.all
  end

  # GET /program_managers/1 or /program_managers/1.json
  def show
  end

  # GET /program_managers/new
  def new
    @program_manager = ProgramManager.new
  end

  # GET /program_managers/1/edit
  def edit
  end

  # POST /program_managers or /program_managers.json
  def create
    @program_manager = ProgramManager.new(program_manager_params)

    respond_to do |format|
      if @program_manager.save
        format.html { redirect_to program_manager_url(@program_manager), notice: "Program manager was successfully created." }
        format.json { render :show, status: :created, location: @program_manager }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @program_manager.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /program_managers/1 or /program_managers/1.json
  def update
    respond_to do |format|
      if @program_manager.update(program_manager_params)
        format.html { redirect_to program_manager_url(@program_manager), notice: "Program manager was successfully updated." }
        format.json { render :show, status: :ok, location: @program_manager }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @program_manager.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /program_managers/1 or /program_managers/1.json
  def destroy
    @program_manager.destroy

    respond_to do |format|
      format.html { redirect_to program_managers_url, notice: "Program manager was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_program_manager
      @program_manager = ProgramManager.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def program_manager_params
      params.require(:program_manager).permit(:uniqname, :first_name, :last_name)
    end
end
