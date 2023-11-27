class Programs::CoursesController < ApplicationController
  before_action :auth_user
  before_action :set_course_program
  before_action :set_course, only: %i[ show edit update destroy ]

  # GET /courses or /courses.json
  def index
    @courses = @course_program.courses
    @course = Course.new
    authorize([@course_program, @course]) 
  end

  # GET /courses/1 or /courses/1.json
  def show
  end

  # GET /courses/new
  def new
    @course = Course.new
    authorize([@course_program, @course]) 
  end

  # GET /courses/1/edit
  def edit
  end

  # POST /courses or /courses.json
  def create
    @course = Course.new(course_params)
    @course.program_id = @course_program.id
    authorize([@course_program, @course])
    if @course.save
      @course_program.update(not_course: false)
      @course = Course.new
      flash.now[:notice] = "Course list is updated"
    end
    @courses = @course_program.courses
  end

  # PATCH/PUT /courses/1 or /courses/1.json
  def update
    if @course.update(course_params)
      @course = Course.new
      @courses = @course_program.courses
      redirect_to program_courses_path(@course_program), notice: "Course was successfully updated." 
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /courses/1 or /courses/1.json
  def destroy
    students = @course.students
    students.each do |student|
      if student.reservations.present?
        student.update(registered: false, course_id: nil)
      else
        student.delete
      end
    end
    if @course.destroy
      @courses = @course_program.courses
      @course = Course.new
      flash.now[:notice] = "Course is removed"
    else
      @courses = @program.courses
      render :index, status: :unprocessable_entity
    end

  end

  private

    def set_course_program
      @course_program = Program.find(params[:program_id])
    end
      
    def set_course
      @course = Course.find(params[:id])
      authorize([@course_program, @course]) 
    end

    # Only allow a list of trusted parameters through.
    def course_params
      params.require(:course).permit(:subject, :catalog_number, :class_section, :program_id)
    end
end
