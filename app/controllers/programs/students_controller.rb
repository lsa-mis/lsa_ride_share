class Programs::StudentsController < ApplicationController
  before_action :set_student, only: %i[ show ]
  before_action :set_student_program
  include StudentApi

  # GET /students or /students.json
  def index
    @students = @student_program.students
    unless @students.present?
      call_api = get_student_list(@student_program)
      flash[:notice] = call_api
    end
  end

  def update_student_list
    call_api = update_students(@student_program)
    redirect_to program_students_path(@student_program), notice: call_api
  end

  # GET /students/1 or /students/1.json
  def show
  end

  def update_mvr_status
    @student_program.students.each do |student|
      status = mvr_status(student.uniqname)
      student.update(mvr_status: status)
    end
    redirect_to program_students_path(@student_program), notice: "MVR status updates"
  end

  def canvas_results
    scope = "canvasreadonly"
    token = get_auth_token(scope)
     # course_id = 187918, test with 187919, 187918999
    result = canvas_readonly(@student_program.canvas_course_id, token['access_token'])
    if result['success']
      students =  @student_program.students.pluck(:uniqname)
      result['data'].each do |uniqname, date|
        if students.include?(uniqname)
          Student.find_by(uniqname: uniqname).update(canvas_course_complete_date: date)
        end
      end
      redirect_to program_students_path(@student_program), notice: "Canvas course data updated"
    else
      redirect_to program_students_path(@student_program), alert: result['error']
    end
  end

  private

    def set_student_program
        @student_program = Program.find(params[:program_id])
    end

    def set_student
      fail
      @student = Student.find(params[:id])
    end

    def get_student_list(program)
      scope = "classroster"
      token = get_auth_token(scope)
      result = class_roster_operational(program.term.code, program.subject, program.catalog_number, program.class_section, token['access_token'])
      if result['success']
        data = result['data']['Classes']['Class']['ClassSections']['ClassSection']['ClassStudents']['ClassStudent']
        data.each do |student_info|
          student = Student.new(uniqname: student_info['Uniqname'], first_name: student_info['Name'].split(",").last, last_name: student_info['Name'].split(",").first)
          if student.save
            @student_program.students << student
          end
        end
        return "Student List is created"
      else
        return result['errorcode'] + ": " + result['error']
      end
    end

    def update_students(program)
      scope = "classroster"
      token = get_auth_token(scope)
      result = class_roster_operational(program.term.code, program.subject, program.catalog_number, program.class_section, token['access_token'])
      if result['success']
        data = result['data']['Classes']['Class']['ClassSections']['ClassSection']['ClassStudents']['ClassStudent']
        students_in_db = @student_program.students.pluck(:uniqname)
        data.each do |student_info|
          uniqname = student_info['Uniqname']
          if students_in_db.include?(uniqname)
            students_in_db.delete(uniqname)
          else
            student = Student.new(uniqname: student_info['Uniqname'], first_name: student_info['Name'].split(",").last, last_name: student_info['Name'].split(",").first)
            if student.save
              @student_program.students << student
            end
          end
        end
        if students_in_db.present?
          @student_program.students.delete(Student.where(uniqname: students_in_db))
        end
        return "Student list is updated"
      else
        return result['errorcode'] + ": " + result['error']
      end
    end

    # Only allow a list of trusted parameters through.
    def student_params
      params.require(:student).permit(:uniqname, :last_name, :first_name, :mvr_expiration_date, :class_training_date, :canvas_course_complete_date, :meeting_with_admin_date)
    end

end