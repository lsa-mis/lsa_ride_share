class StudentsController < ApplicationController
  before_action :auth_user
  before_action :set_units
  include StudentApi

  def index
    if params[:unit_id].present?
      @programs = Program.where(unit_id: params[:unit_id])
    else
      @programs = Program.where(unit_id: session[:unit_ids])
    end
    programs_ids = @programs.data(params[:term_id]).pluck(:id)
    @students = Student.where(program_id: programs_ids).map { |s| [s.uniqname, s.display_name] }.sort_by { |s| s[1] }.uniq
    authorize Student
  end

  def get_programs_for_uniqname
    uniqnames = params[:uniqnames].split(',') 
    students = Student.where(uniqname: uniqnames, program: Program.current_term)
    @students_data = []
    students.each do |student|
      @students_data << { student_id: student.id, student_name: student.display_name, 
        program_id: student.program.id, program_name: student.program.display_name_with_title_and_unit }
    end
    authorize Student
  end

  private

    def set_units
      if is_admin?
        @units = Unit.where(id: session[:unit_ids]).order(:name)
      else
        @units = []
      end
    end
end
