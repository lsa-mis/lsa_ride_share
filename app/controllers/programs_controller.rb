class ProgramsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_program, only: %i[ show edit update destroy duplicate remove_car]

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
  end

  # GET /programs/new
  def new
    @program = Program.new
    @terms = Term.all
  end

  # GET /programs/1/edit
  def edit
  end

  # POST /programs or /programs.json
  def create
    @program = Program.new(program_params)

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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_program
      @program = Program.find(params[:id])
      @terms = Term.all
    end

    # Only allow a list of trusted parameters through.
    def program_params
      params.require(:program).permit(:active, :title, :term_start, :term_end, :term_id, :subject, :catalog_number, :class_section, 
                                     :number_of_students, :number_of_students_using_ride_share, :pictures_required_start, :pictures_required_end, 
                                     :non_uofm_passengers, :instructor_id, :admin_access_id, :updated_by)
    end
end
