class WelcomePagesController < ApplicationController
  before_action :auth_user
  include StudentApi

  def student
    @students = Student.where(uniqname: current_user.uniqname, program: Program.current_term)
    @students_data = @students.map { |s| [s.program.display_name_with_title_and_unit, s.id] }
    program_ids = @students.map { |p| p.program.id }
    unit_ids = Program.where(id: program_ids).pluck(:unit_id) 
    if params[:student_id].present?
      @student = Student.find(params[:student_id])
      @program = @student.program
    elsif @students.count == 1
      @student = @students[0]
      @program = @student.program
    end
    if @student.present?
      update_status(@student)
      @reservations_past = @student.reservations_past.sort_by(&:start_time).reverse
      @reservations_future = @student.reservations_future.sort_by(&:start_time)
      unit_ids = [@program.unit_id]
    else
      @reservation = []
    end
    @contact_data = UnitPreference.select(:unit_id, :name, :value).where(unit_id: unit_ids).where("name = 'unit_office' OR name = 'contact_phone'").group_by(&:unit_id).to_a
    authorize :welcome_page
  end

  def update_status(resource)
    if resource.mvr_status.present?
      unless resource.mvr_status.include?("Approved")
        status = mvr_status(resource.uniqname)
        resource.update(mvr_status: status)
      end
    else 
      status = mvr_status(resource.uniqname)
        resource.update(mvr_status: status)
    end
    unless resource.canvas_course_complete_date.present?
      canvas_date = update_my_canvas_status(resource)
      if canvas_date 
        resource.update(canvas_course_complete_date: canvas_date)
      end
    end
  end

  def manager
    @manager = Manager.find_by(uniqname: current_user.uniqname)
    update_status(@manager)
    unit_ids = @manager.programs.pluck(:unit_id).uniq
    @programs = @manager.programs
    if @programs.count == 1
      @program = @programs.first
    end
    if params[:program_id].present?
      @program = Program.find(params[:program_id])
      @unit_id = @program.unit.id
    end
    @contact_data = UnitPreference.select(:unit_id, :name, :value).where(unit_id: unit_ids).where("name = 'unit_office' OR name = 'contact_phone'").group_by(&:unit_id).to_a
    if @program.present?
      @reservations_past = @manager.reservations_past.where(program_id: @program.id).sort_by(&:start_time).reverse
      @reservations_future = @manager.reservations_future.where(program_id: @program.id).sort_by(&:start_time)
      unit_ids = [@program.unit_id]
    else
      @reservation = []
    end
    authorize :welcome_page
  end

end
