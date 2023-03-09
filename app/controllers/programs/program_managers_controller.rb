class Programs::ProgramManagersController < ApplicationController
  before_action :set_program_manager_program

  def new
    @program_manager = ProgramManager.new
  end

  def create
    uniqname = params[:program_manager][:uniqname]
    program_manager = ProgramManager.new(program_manager_params)
    respond_to do |format|
      if program_manager.save
        @program_manager_program.program_managers << program_manager
        format.html { redirect_to @program_manager_program, notice: "The program manager was added" }
        format.json { render :show, status: :created, location: @program_manager_program }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @program_manager_program.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @program_manager = ProgramManager.find(params[:id])
    @program_manager.destroy

    respond_to do |format|
      format.html { redirect_to program_managers_url, notice: "Program manager was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

    def set_program_manager_program
        @program_manager_program = Program.find(params[:program_id])
    end

    # Only allow a list of trusted parameters through.
    def program_manager_params
      params.require(:program_manager).permit(:uniqname, :first_name, :last_name)
    end

end
