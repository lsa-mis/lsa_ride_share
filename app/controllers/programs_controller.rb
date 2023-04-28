class ProgramsController < ApplicationController
  before_action :auth_user

  before_action :set_program, except: %i[ index new create]
  before_action :set_terms_and_units

  include ApplicationHelper

  # GET /programs or /programs.json
  def index
    if params[:unit_id].present?
      @programs = Program.where(unit_id: params[:unit_id])
    else
      @programs = Program.where(unit_id: current_user.unit)
    end
    @programs = @programs.data(params[:term_id])
    authorize @programs

  end

  def duplicate
    @program = @program.dup
    render :new
  end

  # GET /programs/1 or /programs/1.json
  def show
  end

  # GET /programs/new
  def new
    @program = Program.new
    @program.mvr_link = "https://ltp.umich.edu/fleet/vehicle-use/"
    @instructor = ProgramManager.new
    authorize @program
  end

  # GET /programs/1/edit
  def edit
  end

  def program_data
    @cars = @program.cars
    @add_cars = Car.all - @cars
  end

  # POST /programs or /programs.json
  def create
    
    @program = Program.new(program_params.except(:instructor_attributes))
    uniqname = program_params[:instructor_attributes][:uniqname]
    if ProgramManager.find_by(uniqname: uniqname).present?
      instructor = ProgramManager.find_by(uniqname: uniqname)
    else
      instructor = ProgramManager.create(uniqname: uniqname)
    end
    @program.instructor = instructor
    authorize @program
    respond_to do |format|
      if @program.save
        format.html { redirect_to program_url(@program), notice: "Program was successfully created." }
        format.json { render :show, status: :created, location: @program }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @program.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /programs/1 or /programs/1.json
  def update
    uniqname = program_params[:instructor_attributes][:uniqname]
    if ProgramManager.find_by(uniqname: uniqname).present?
      instructor = ProgramManager.find_by(uniqname: uniqname)
    else
      instructor = ProgramManager.create(uniqname: uniqname)
    end
    @program.instructor_id = instructor.id
    authorize @program
    respond_to do |format|
      if @program.update(program_params.except(:instructor_attributes))
        format.html { redirect_to program_data_path(@program), notice: "Program was successfully updated." }
        format.json { render :show, status: :ok, location: @program }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @program.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /programs/1 or /programs/1.json
  def destroy
    @program.destroy

    respond_to do |format|
      format.html { redirect_to programs_url, notice: "Program was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def remove_car
    @program.cars.delete(Car.find(params[:car_id]))
    redirect_to @program
  end

  def remove_site
    @program.sites.delete(Site.find(params[:site_id]))
    redirect_to @program
  end

  def remove_program_manager
    @program.program_managers.delete(ProgramManager.find(params[:program_manager_id]))
    redirect_to @program
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_program
      @program = Program.find(params[:id])
      authorize @program
    end

    def set_terms_and_units
      @terms = Term.sorted
      @units = Unit.where(id: current_user.unit).order(:name)
    end

    # Only allow a list of trusted parameters through.
    def program_params
      params.require(:program).permit(:active, :title, :term_id, :subject, :catalog_number, :class_section, 
                                     :number_of_students, :number_of_students_using_ride_share, :pictures_required_start, :pictures_required_end, 
                                     :non_uofm_passengers, :instructor_id, :mvr_link, :canvas_link, :canvas_course_id, :unit_id, :add_managers, 
                                     :not_course, :updated_by, instructor_attributes: [:uniqname])
    end
end
