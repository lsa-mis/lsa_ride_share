class Programs::ProgramManagersController < ProgramManagersController
  before_action :set_program_manager_program

  private

  def set_program_manager_program
      @program_manager_program = Program.find(params[:program_id])
  end

end