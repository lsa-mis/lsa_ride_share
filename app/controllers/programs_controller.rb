class ProgramsController < ApplicationController
  before_action :auth_user

  before_action :set_program, except: %i[ index new create get_programs_list get_students_list get_sites_list ]
  before_action :set_units
  before_action :set_terms, only: %i[ duplicate new edit create update]

  include ApplicationHelper

  # GET /programs or /programs.json
  def index
    @terms = Term.sorted
    if params[:unit_id].present?
      @programs = Program.where(unit_id: params[:unit_id])
    else
      @programs = Program.where(unit_id: current_user.unit_ids)
    end
    @programs = @programs.data(params[:term_id])
    if is_manager?(current_user)
      @programs = Program.all.data(params[:term_id])
      programs = Manager.find_by(uniqname: current_user.uniqname).programs
      @programs = @programs.where(id: programs.map(&:id))
    end
    authorize @programs

  end

  def duplicate
    @duplicate_program_id = @program.id
    @terms.delete(@program.term)
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
    @instructor = Manager.new
    authorize @program
  end

  # GET /programs/1/edit
  def edit
  end

  def program_data
  end

  # POST /programs or /programs.json
  def create
    note = ''
    @program = Program.new(program_params.except(:instructor_attributes, :duplicate_program_id))
    authorize @program
    uniqname = program_params[:instructor_attributes][:uniqname]
    result = get_instructor_id(uniqname)
    if result['valid']
      @program.instructor_id = result['instructor_id']
      note = result['note']
    else
      flash.now[:alert] = "The '#{uniqname}' uniqname is not valid."
      return
    end
    if @program.save
      if params[:program][:duplicate_program_id].present?
        # carry forward sites when program is carried forward
        @program.sites << Program.find(params[:program][:duplicate_program_id]).sites
      end
      redirect_to program_data_path(@program), notice: "Program was successfully created." + note
    end
  end

  # PATCH/PUT /programs/1 or /programs/1.json
  def update
    note = ''
    @program.attributes = program_params.except(:instructor_attributes)
    @program.instructor.attributes = program_params[:instructor_attributes]
    if @program.instructor.uniqname_changed?
      result = get_instructor_id(@program.instructor.uniqname)
      if result['valid']
        @program.instructor_id = result['instructor_id']
        note = result['note']
      else
        flash.now[:alert] = "The '#{@program.instructor.uniqname}' uniqname is not valid."
        render :edit, status: :unprocessable_entity
        return
      end
    end
    if @program.save
      redirect_to program_data_path(@program), notice: "Program was successfully updated." + note
    end
  end

  def get_instructor_id(uniqname)
    result = {'valid' => false, 'note' => '', 'instructor_id' => 0}
    if Manager.find_by(uniqname: uniqname).present?
      result['valid'] =  true
      result['instructor_id'] = Manager.find_by(uniqname: uniqname).id
    else
      @instructor = Manager.new(uniqname: uniqname)
      name = LdapLookup.get_simple_name(uniqname)
      if name == "No such user"
        result['note'] = "The '#{uniqname}' uniqname is not valid."
      else
        result['valid'] =  true
        if name.nil?
          result['note'] = "Mcommunity returns no name for '#{uniqname}' uniqname."
          @instructor.first_name = ''
          @instructor.last_name = ''
        else
          @instructor.first_name = name.split(" ").first
          @instructor.last_name = name.split(" ").last
        end
        if @instructor.save
          result['instructor_id'] = instructor.id
        else 
          result['valid'] =  false
          result['note'] = 'Error saving instructor record. Please report the issue'
        end
      end
    end
    return result
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

  def get_programs_list
    render json: Program.where(unit_id: params[:unit_id], term: params[:term_id])
    authorize Program
  end

  def get_students_list
    render json: Program.find(params[:program_id]).students
    authorize Program
  end

  def get_sites_list
    render json: Program.find(params[:program_id]).sites
    authorize Program
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_program
      @program = Program.find(params[:id])
      authorize @program
    end

    def set_units
      @units = Unit.where(id: current_user.unit_ids).order(:name)
    end

    def set_terms
      @terms = Term.current_and_future
    end

    # Only allow a list of trusted parameters through.
    def program_params
      params.require(:program).permit(:active, :title, :term_id, :subject, :catalog_number, :class_section, 
                                     :number_of_students, :number_of_students_using_ride_share, :pictures_required_start, :pictures_required_end, 
                                     :non_uofm_passengers, :instructor_id, :mvr_link, :canvas_link, :canvas_course_id, :unit_id, :add_managers, 
                                     :not_course, :updated_by, :duplicate_program_id, instructor_attributes: [:id, :uniqname])
    end
end
