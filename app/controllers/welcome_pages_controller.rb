class WelcomePagesController < ApplicationController
  before_action :auth_user

  def student
    user = User.second
    @student = Student.find_by(uniqname: user.uniqname, program: Program.current_term)
    @program = @student.program
    @reservations = @student.reservations
    authorize :welcome_page
  end
end
