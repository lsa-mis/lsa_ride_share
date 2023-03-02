class ProgramsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_program, only: %i[ show edit update destroy duplicate remove_car remove_site remove_program_manager add_config_questions remove_config_question]
  before_action :set_terms

  include ApplicationHelper

  # GET /programs or /programs.json
  def index
    @terms = Term.all
    if params[:active].present?
      @programs = Program.where(active: params[:active])
    else
      @programs = Program.active
    end
    if params[:term_id].present?
      @programs = Program.where(term_id: params[:term_id])
    else
      @programs = Program.active
    end

    if @programs.present?
      @term_id = @programs.last.term_id
    else
      @term_id = nil
    end

  end

  def duplicate
    @program = @program.dup
    render :new
  end

  # GET /programs/1 or /programs/1.json
  def show
    @cars = @program.cars
    @add_cars = Car.all - @cars
    @terms = Term.all
  end

  # GET /programs/new
  def new
    @program = Program.new
    @instructor = ProgramManager.new
    @terms = Term.all
  end

  # GET /programs/1/edit
  def edit
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
    respond_to do |format|
      if @program.update(program_params)
        format.html { redirect_to program_url(@program), notice: "Program was successfully updated." }
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

  def add_config_questions
    default_config_questions.each do |q|
      config_question = ConfigQuestion.new(program_id: @program.id, question: q)
      config_question.save
    end
    redirect_to @program
  end

  def remove_config_question
    ConfigQuestion.find(params[:config_question_id]).delete
    redirect_to @program
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_program
      @program = Program.find(params[:id])
    end

    def set_terms
      @terms = Term.all
    end

    # Only allow a list of trusted parameters through.
    def program_params
      params.require(:program).permit(:active, :title, :term_start, :term_end, :term_id, :subject, :catalog_number, :class_section, 
                                     :number_of_students, :number_of_students_using_ride_share, :pictures_required_start, :pictures_required_end, 
                                     :non_uofm_passengers, :instructor_id, :admin_access_id, :updated_by, instructor_attributes: [:uniqname])
    end
end
