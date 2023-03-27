class Programs::StudentsController < ApplicationController
  before_action :auth_user
  before_action :set_student, only: %i[ show destroy]
  before_action :set_student_program
  include StudentApi

  # GET /students or /students.json
  def index
    unless @student_program.not_course
      update_students(@student_program)
    end
    @students = @student_program.students.order(:last_name)
    authorize @students
  end

  def update_student_list
    # to test create program with: subject = RCCORE, catalog_number = 205, section = 165
    update_students(@student_program)
    @students = @student_program.students.order(:last_name)
    authorize @students
  end

  def add_students
    @student = Student.new
    @students = @student_program.students.order(:last_name)
    authorize Student
    @no_name = false
  end

  def create
    uniqname = student_params[:uniqname]
    @student = Student.new(uniqname: uniqname)
    authorize @student
    if params[:correct_uniqname].present?
      @student = Student.new(student_params)
    else
      name = LdapLookup.get_simple_name(uniqname)
      if name.nil?
        flash.now[:alert] = "Mcommunity returns no name for '#{uniqname}' uniqname. If the uniqname is correct, please check the checkbox and enter last and first name manually"
        @no_name = true
        @students = @student_program.students.order(:last_name)
        return
      else
        @no_name = false
        @student.first_name = name.split(" ").first
        @student.last_name = name.split(" ").last
      end
    end
    @student.program_id = @student_program.id
    if @student.save
      @student = Student.new
      flash.now[:notice] = "Student list is updated"
    end
    @students = @student_program.students.order(:last_name)
  end

  def destroy
    authorize @student
    if @student.destroy
      @students = @student_program.students.order(:last_name)
      @student = Student.new
      flash.now[:notice] = "Student is removed"
    else
      @students = @student_program.students.order(:last_name)
      render :add_students, status: :unprocessable_entity
    end

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
    authorize @students
  end

  def canvas_results
    scope = "canvasreadonly"
    token = get_auth_token(scope)
    if token['success']
      result = canvas_readonly(@student_program.canvas_course_id, token['access_token'])
    else
      flash.now[:alert] = token['error']
      @students = @student_program.students.order(:last_name)
      return
    end
     # to test: course_id = 187918
    if result['success']
      students_with_good_score = result['data']
      uniqnames = students_with_good_score.keys
      @student_program.students.each do |student|
        if uniqnames.include?(student.uniqname)
          unless student.update(canvas_course_complete_date: students_with_good_score[student.uniqname])
            flash.now[:alert] = "Error updating student record"
            @students = @student_program.students.order(:last_name)
            return
          end
        end
      end
      flash.now[:notice] = "Canvas results are updated"
    else
      flash.now[:alert] = result['error']
    end
    @students = @student_program.students.order(:last_name)
    authorize @students
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
