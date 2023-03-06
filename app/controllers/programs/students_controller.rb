class Programs::StudentsController < StudentsController
  before_action :set_student_program

  private

  def set_student_program
      @student_program = Program.find(params[:program_id])
  end

end