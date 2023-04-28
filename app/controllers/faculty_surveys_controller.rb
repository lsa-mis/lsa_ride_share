class FacultySurveysController < ApplicationController
  before_action :set_faculty_survey, only: %i[ show edit update destroy ]
  before_action :set_units_terms, only: %i[ new edit ]
  include ApplicationHelper

  # GET /faculty_surveys or /faculty_surveys.json
  def index
    @faculty_surveys = FacultySurvey.where(unit_id: current_user.unit)
    authorize @faculty_surveys
  end

  # GET /faculty_surveys/1 or /faculty_surveys/1.json
  def show
  end

  # GET /faculty_surveys/new
  def new
    @faculty_survey = FacultySurvey.new
    authorize @faculty_survey
  end

  # GET /faculty_surveys/1/edit
  def edit
  end

  # POST /faculty_surveys or /faculty_surveys.json
  def create
    @faculty_survey = FacultySurvey.new(faculty_survey_params)
    authorize @faculty_survey
    if @faculty_survey.save
      add_config_questions(@faculty_survey)
      redirect_to faculty_surveys_path, notice: "Faculty survey was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /faculty_surveys/1 or /faculty_surveys/1.json
  def update
    if @faculty_survey.update(faculty_survey_params)
      redirect_to faculty_surveys_path, notice: "Faculty survey was successfully updated."
    else
      ender :edit, status: :unprocessable_entity
    end
  end

  # DELETE /faculty_surveys/1 or /faculty_surveys/1.json
  def destroy
    @faculty_survey.destroy

    respond_to do |format|
      format.html { redirect_to faculty_surveys_url, notice: "Faculty survey was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def add_config_questions(faculty_survey)
    default_config_questions.each do |q|
      config_question = ConfigQuestion.new(faculty_survey_id: faculty_survey.id, question: q)
      config_question.save
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_faculty_survey
      @faculty_survey = FacultySurvey.find(params[:id])
      authorize @faculty_survey
    end

    def set_units_terms
      @terms = Term.all
      @units = Unit.where(id: current_user.unit).order(:name)
    end

    # Only allow a list of trusted parameters through.
    def faculty_survey_params
      params.require(:faculty_survey).permit(:uniqname, :term_id, :unit_id)
    end
end
