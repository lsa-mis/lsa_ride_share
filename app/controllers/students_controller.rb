class StudentsController < ApplicationController
  before_action :set_student, only: %i[ show edit update destroy ]
  include StudentApi

  # GET /students or /students.json
  def index
    @students = @student_program.students
    unless @students.present?
      call_api = student_list(@student_program)
      flash[:notice] = call_api
    end
  end

  # GET /students/1 or /students/1.json
  def show
  end

  # GET /students/new
  def new
    @student = Student.new
  end

  # GET /students/1/edit
  def edit
  end

  # POST /students or /students.json
  def create
    @student = Student.new(student_params)

    respond_to do |format|
      if @student.save
        format.html { redirect_to student_url(@student), notice: "Student was successfully created." }
        format.json { render :show, status: :created, location: @student }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @student.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /students/1 or /students/1.json
  def update
    respond_to do |format|
      if @student.update(student_params)
        format.html { redirect_to student_url(@student), notice: "Student was successfully updated." }
        format.json { render :show, status: :ok, location: @student }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @student.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /students/1 or /students/1.json
  def destroy
    @student.destroy

    respond_to do |format|
      format.html { redirect_to students_url, notice: "Student was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_student
      @student = Student.find(params[:id])
    end

    def student_list(program)
      scope = "classroster"
      token = get_auth_token(scope)
      result = class_roster_operational(2420, "RCCORE", 205, 165, token['access_token'])
      if result['success']
        data = result['data']['Classes']['Class']['ClassSections']['ClassSection']['ClassStudents']['ClassStudent']
        data.each do |student|
          student = Student.new(uniqname: student['Uniqname'], first_name: student['Name'].split(",").last, last_name: student['Name'].split(",").first)
          if student.save
            @student_program.students << student
          end
        end
        return "success"
      else
        return result['errorcode'] + ": " + result['error']
      end
    end

    # Only allow a list of trusted parameters through.
    def student_params
      params.require(:student).permit(:uniqname, :last_name, :first_name, :mvr_expiration_date, :class_training_date, :canvas_course_complete_date, :meeting_with_admin_date)
    end
end
