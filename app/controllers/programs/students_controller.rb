class Programs::StudentsController < ApplicationController
  before_action :set_student, only: %i[ show ]
  before_action :set_student_program
  include StudentApi

  # GET /students or /students.json
  def index
    update_students(@student_program)
    # flash[:notice] = call_api_message
    @students = @student_program.students.order(:last_name)
  end

  def update_student_list
    update_students(@student_program)
    # flash[:notice] = call_api_message
    @students = @student_program.students.order(:last_name)
  end

  # GET /students/1 or /students/1.json
  def show
  end

  def update_mvr_status
    @student_program.students.each do |student|
      status = mvr_status(student.uniqname)
      unless student.update(mvr_status: status)
        redirect_to program_students_path(@student_program), alert: "Error updating student record"
      end
    end
    flash.now[:notice] = "MVR status is updated"
    @students = @student_program.students.order(:last_name)
  end

  def canvas_results
    scope = "canvasreadonly"
    token = get_auth_token(scope)
     # course_id = 187918, test with 187919, 187918999
    result = canvas_readonly(@student_program.canvas_course_id, token['access_token'])
    if result['success']
      students_with_good_score = result['data']
      uniqnames = students_with_good_score.keys
      @student_program.students.each do |student|
        if uniqnames.include?(student.uniqname)
          unless student.update(canvas_course_complete_date: students_with_good_score[student.uniqname])
            flash.now[:alert] = "Error updating student record"
            return
          end
        end
      end
      flash.now[:notice] = "Canvas results are updated"
    else
      flash.now[:alert] = result['error']
    end
    @students = @student_program.students.order(:last_name)
  end

  private

    def set_student_program
        @student_program = Program.find(params[:program_id])
    end

    def set_student
      @student = Student.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def student_params
      params.require(:student).permit(:uniqname, :last_name, :first_name, :mvr_expiration_date, :class_training_date, :canvas_course_complete_date, :meeting_with_admin_date)
    end

end