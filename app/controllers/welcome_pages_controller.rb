class WelcomePagesController < ApplicationController
  before_action :auth_user

  def student
    @user = User.second
    @students = Student.where(uniqname: @user.uniqname, program: Program.current_term)
    @students_data = @students.map { |s| [s.program.display_name_with_title, s.id] }
    @reservation = []
    if params[:student_id].present?
      @student = Student.find(params[:student_id])
      @program = @student.program
      @reservations = @student.reservations
    elsif @students.count == 1
      @student = @students[0]
      @program = @student.program
      @reservations = @student.reservations
    end
    authorize :welcome_page
  end
end
