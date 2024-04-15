class WelcomePagesController < ApplicationController
  before_action :auth_user
  include StudentApi

  def student
    authorize :welcome_page
    @students = Student.where(uniqname: current_user.uniqname, program: Program.current_term)
    @students_data = @students.map { |s| [s.program.display_name_with_title_and_unit, s.id] }
    program_ids = @students.map { |p| p.program.id }
    unit_ids = Program.where(id: program_ids).pluck(:unit_id)
    @unit_names =  Unit.all.pluck(:name).join(", ").reverse.sub(',', ' dna ,').reverse
    if params[:student_id].present?
      @student = Student.find(params[:student_id])
      @program = @student.program
    elsif @students.count == 1
      @student = @students[0]
      @program = @student.program
    end
    if @student.present?
      update_status(@student, @student.program)
      @reservations_current = @student.reservations_current.sort_by(&:start_time)
      @reservations_past = @student.reservations_past.sort_by(&:start_time).reverse
      @reservations_future = @student.reservations_future.sort_by(&:start_time)
      unit_ids = [@program.unit_id]
    else
      @reservation = []
    end
    @contact_data = UnitPreference.select(:unit_id, :name, :value).where(unit_id: unit_ids).where("name = 'unit_office' OR name = 'contact_phone' OR name = 'notification_email'").group_by(&:unit_id).to_a
  end

  def update_status(resource, program)
    if resource.mvr_status.present?
      unless resource.mvr_status.include?("Approved")
        status = mvr_status(resource.uniqname)
        resource.update(mvr_status: status)
      end
    else 
      status = mvr_status(resource.uniqname)
        resource.update(mvr_status: status)
    end
    # unless resource.canvas_course_complete_date.present?
    #   canvas_date = update_my_canvas_status(resource, program)
    #   if canvas_date 
    #     resource.update(canvas_course_complete_date: canvas_date)
    #   end
    # end
  end

  def manager
    authorize :welcome_page
    @manager = Manager.find_by(uniqname: current_user.uniqname)
    unit_ids = @manager.programs.pluck(:unit_id).uniq
    @programs = @manager.programs.sort_by(&:title)
    if @programs.count == 1
      @program = @programs.first
    end
    if params[:program_id].present?
      @program = Program.find(params[:program_id])
      @unit_id = @program.unit.id
    end
    @contact_data = UnitPreference.select(:unit_id, :name, :value).where(unit_id: unit_ids).where("name = 'unit_office' OR name = 'contact_phone' OR name = 'notification_email'").group_by(&:unit_id).to_a
    if @program.present?
      update_status(@manager, @program)
      @reservations_current = (@manager.passenger_current.where(program_id: @program.id) + 
        @manager.reserved_by_or_driver_current.where(program_id: @program.id)).sort_by(&:start_time)
      @reservations_past = (@manager.passenger_past.where(program_id: @program.id) + 
        @manager.reserved_by_or_driver_past.where(program_id: @program.id)).sort_by(&:start_time).reverse
      @reservations_future = (@manager.passenger_future.where(program_id: @program.id) + 
        @manager.reserved_by_or_driver_future.where(program_id: @program.id)).sort_by(&:start_time)
      unit_ids = [@program.unit_id]
    else
      @reservation = []
    end
  end

  def add_phone
    authorize :welcome_page
    phone_number = params[:phone_number]
    @student = Student.find(params[:id])
    if @student.update(phone_number: phone_number)
      redirect_to welcome_pages_student_path notice: "The phone was updated."

      # @student = Student.find(params[:id])
      # render turbo_stream: turbo_stream.replace("student_phone", partial: "phone_number")
    else
      fail
    end
  end

  def edit_phone
    @student = Student.find(params[:id])
    authorize :welcome_page
  end

end
