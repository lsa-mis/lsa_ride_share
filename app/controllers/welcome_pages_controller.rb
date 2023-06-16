class WelcomePagesController < ApplicationController
  before_action :auth_user

  def student
    @students = Student.where(uniqname: current_user.uniqname, program: Program.current_term)
    @students_data = @students.map { |s| [s.program.display_name_with_title_and_unit, s.id] }
    program_ids = @students.map { |p| p.program.id }
    unit_ids = Program.where(id: program_ids).pluck(:unit_id) 
    @contact_data = UnitPreference.select(:unit_id, :name, :value).where(unit_id: unit_ids).where("name = 'unit_office' OR name = 'contact_phone'").group_by(&:unit_id).to_a
    if params[:student_id].present?
      @student = Student.find(params[:student_id])
      @program = @student.program
    elsif @students.count == 1
      @student = @students[0]
      @program = @student.program
    end
    if @student.present?
      @reservations_past = @student.reservations_past.sort_by(&:start_time).reverse
      @reservations_future = @student.reservations_future.sort_by(&:start_time)
    else
      @reservation = []
    end
    authorize :welcome_page
  end
end
