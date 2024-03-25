class Programs::StudentsController < ApplicationController
  before_action :auth_user
  before_action :set_student, only: %i[ show edit update destroy update_student_mvr_status student_canvas_result]
  before_action :set_student_program
  before_action :set_students_list, only: %i[ index update_student_list add_students ]
  include StudentApi

  # GET /students or /students.json
  def index
    unless params[:update] == "false"
      unless @student_program.not_course
        update_students(@student_program)
      end
    end
    authorize @students
    if params[:format] == "csv"
      respond_to do |format|
        format.csv { send_data @students.to_csv, filename: "students-#{Date.today}.csv"}
      end
    end 
  end

  def update_student_list
    update_students(@student_program)
    authorize @students
  end

  def add_students
    @student = Student.new
    authorize Student
  end

  def create
    uniqname = student_params[:uniqname]
    @student = Student.new(student_params)
    authorize @student
    result = get_name(uniqname)
    if result['valid']
      @student.first_name = result['first_name']
      @student.last_name = result['last_name']
      if @student.save
        @student_program.update(number_of_students: @student_program.students.count)
        @student = Student.new
        flash.now[:notice] = "Student list is updated." + result['note']
      end
    else
      flash.now[:alert] = result['note']
      @students = @student_program.students.order(registered: :desc).order(:last_name)
      return
    end
    @students = @student_program.students.order(registered: :desc).order(:last_name)
  end

  def destroy
    if @student.reservations.present?
      flash.now[:alert] = "Student has reservations and can't be removed."
      @student = Student.new
      @students = @student_program.students.order(registered: :desc).order(:last_name)
      return
    else
      authorize @student
      if @student.destroy
        @student_program.update(number_of_students: @student_program.students.count)
        @students = @student_program.students.order(registered: :desc).order(:last_name)
        @student = Student.new
        flash.now[:notice] = "Student is removed."
      else
        @students = @student_program.students.order(registered: :desc).order(:last_name)
        render :add_students, status: :unprocessable_entity
      end
    end

  end

  # GET /students/1 or /students/1.json
  def show
  end

  def edit
  end

  def update
    if @student.update(student_params)
      redirect_to program_student_path(@student_program, @student), notice: "The student record was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update_student_mvr_status
    status = mvr_status(@student.uniqname)
    unless @student.update(mvr_status: status)
      redirect_to program_student_path(@student_program, @student), alert: "Error updating student record."
    end
    flash.now[:notice] = "MVR status is updated."
  end

  def update_mvr_status
    @student_program.students.each do |student|
      if need_to_check_mvr_status?(student)
        status = mvr_status(student.uniqname)
        unless student.update(mvr_status: status)
          redirect_to program_students_path(@student_program), alert: "Error updating student record."
        end
      end
    end
    flash[:notice] = "MVR status is updated."
    @students = @student_program.students.order(registered: :desc).order(:last_name)
    authorize @students
  end

  def student_canvas_result
    scope = "canvasreadonly"
    token = get_auth_token(scope)
    if token['success']
      result = canvas_readonly(@student_program.canvas_course_id, token['access_token'])
    else
      flash.now[:alert] = token['error']
      return
    end
    if result['success']
      students_with_good_score = result['data']
      uniqnames = students_with_good_score.keys
      if uniqnames.include?(@student.uniqname)
        unless @student.update(canvas_course_complete_date: students_with_good_score[@student.uniqname])
          redirect_to program_student_path(@student_program, @student), alert: "Error updating student record."
        end
        flash.now[:notice] = "Student pass the course."
      else
        flash.now[:notice] = "Student did not pass the course."
      end
    else
      flash.now[:alert] = result['error']
    end
  end

  def canvas_results
    scope = "canvasreadonly"
    token = get_auth_token(scope)
    if token['success']
      result = canvas_readonly(@student_program.canvas_course_id, token['access_token'])
    else
      flash.now[:alert] = token['error']
      @students = @student_program.students.order(registered: :desc).order(:last_name)
      return
    end
     # to test: course_id = 187918
    if result['success']
      students_with_good_score = result['data']
      uniqnames = students_with_good_score.keys
      @student_program.students.each do |student|
        if uniqnames.include?(student.uniqname)
          unless student.update(canvas_course_complete_date: students_with_good_score[student.uniqname])
            flash.now[:alert] = "Error updating student record."
            @students = @student_program.students.order(registered: :desc).order(:last_name)
            return
          end
        end
      end
      flash.now[:notice] = "Canvas results are updated."
    else
      flash.now[:alert] = result['error']
    end
    @students = @student_program.students.order(registered: :desc).order(:last_name)
    authorize @students
  end

  private

    def set_student_program
        @student_program = Program.find(params[:program_id])
    end

    def set_student
      @student = Student.find(params[:id])
      authorize @student
    end

    def set_students_list
      @students = @student_program.students.order(registered: :desc).order(:course_id).order(:last_name)
    end

    # Only allow a list of trusted parameters through.
    def student_params
      params.require(:student).permit(:uniqname, :program_id, :registered, :last_name, :first_name, :mvr_expiration_date, :canvas_course_complete_date, :meeting_with_admin_date)
    end

end
