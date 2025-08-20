class Programs::StudentsController < ApplicationController
  before_action :auth_user
  before_action :set_student, only: %i[ show edit update destroy update_student_mvr_status student_canvas_result]
  before_action :set_student_program
  before_action :set_students_list, only: %i[ index update_student_list add_students ]
  include StudentApi
  include MailerHelper

  # GET /students or /students.json
  def index
    update = params[:update]
    if update == "mvr_roster"
      update_mvr_and_roster
    elsif update == "roster"
      update_student_list
    end

    authorize @students
    if params[:format] == "csv"
      respond_to do |format|
        format.csv { send_data @students.to_csv, filename: "#{@student_program.title}-students-#{Date.today}.csv"}
      end
    end 
  end

  def update_mvr_and_roster
    unless @student_program.not_course
      update_student_list
    end
    update_mvr_status(note: false)
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
      # check if uniqname is not admin 
      if is_member_of_admin_groups?(uniqname)
        @students = @student_program.students.order(registered: :desc).order(:last_name)
        flash.now[:alert] = "Admin uniqname can't be added to students list"
        return
      end
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

  def show
    @reservations_current = @student.reservations_current.sort_by(&:start_time)
    @reservations_past = @student.reservations_past.sort_by(&:start_time).reverse
    @reservations_future = @student.reservations_future.sort_by(&:start_time)
  end

  def edit
  end

  def update
    programs_ids = Program.current_term.where(unit_id: session[:unit_ids]).pluck(:id)
    students = Student.where(uniqname: @student.uniqname, program: programs_ids)
    
    if students.count > 1
      updated_results = students.update(student_params.slice(:meeting_with_admin_date, :phone_number))
      
      if updated_results.all?
        notice = "#{students.count} student records with this uniqname are updated."
        redirect_to program_student_path(@student_program, @student), notice: notice
      else
        alert = "Some student records were not updated."
        redirect_to program_student_path(@student_program, @student), alert: alert
      end
    else
      if @student.update(student_params)
        redirect_to program_student_path(@student_program, @student), notice: "Student record is updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  def update_student_mvr_status
    status = mvr_status(@student.uniqname)
    unless @student.update(mvr_status: status)
      redirect_to program_student_path(@student_program, @student), alert: "Error updating student record."
    end
    flash.now[:notice] = "MVR status is updated."
  end

  def update_mvr_status(note: true)
    @student_program.students.each do |student|
      if need_to_check_mvr_status?(student)
        status = mvr_status(student.uniqname)
        unless student.update(mvr_status: status)
          redirect_to program_students_path(@student_program), alert: "Error updating student record."
        end
      end
    end
    if note || @student_program.not_course
      flash.now[:notice] = "MVR status is updated."
    else
      flash.now[:notice] = "Student list and MVR status are updated."
    end
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
        flash.now[:notice] = "Canvas course status is updated."
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
      students_without_canvas_results = @student_program.students.where(canvas_course_complete_date: nil)
      students_without_canvas_results.each do |student|
        if uniqnames.include?(student.uniqname)
          unless student.update(canvas_course_complete_date: students_with_good_score[student.uniqname])
            flash.now[:alert] = "Error updating student record."
            @students = @student_program.students.order(registered: :desc).order(:course_id).order(:last_name)
            return
          end
        end
      end
      flash.now[:notice] = "Canvas course results are updated."
    else
      flash.now[:alert] = result['error']
    end
    @students = @student_program.students.order(registered: :desc).order(:course_id).order(:last_name)
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

    def is_member_of_admin_groups?(uniqname)
      unit_groups = Unit.pluck(:ldap_group) + ['lsa-was-rails-devs']
      unit_groups.each do |group|
        if  LdapLookup.is_member_of_group?(uniqname, group)
          return true
        end
      end
      return false
    end

    # Only allow a list of trusted parameters through.
    def student_params
      params.require(:student).permit(:uniqname, :program_id, :registered, :last_name, :first_name, :mvr_expiration_date, :canvas_course_complete_date, :meeting_with_admin_date, :phone_number)
    end

end
