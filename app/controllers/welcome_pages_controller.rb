class WelcomePagesController < ApplicationController
  before_action :auth_user

  def student
    user = User.second
    @students = Student.where(uniqname: user.uniqname, program: Program.current_term)
    if @students.count > 1
      @students.each do |student|
        
      end
    else 
      @student = @students[0]
      @program = @student.program
      @reservations = @student.reservations
    end
    authorize :welcome_page
  end
end
