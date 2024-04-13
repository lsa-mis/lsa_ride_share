class FacultySurveysController < ApplicationController
  before_action :auth_user
  before_action :set_faculty_survey, only: %i[ show edit update destroy send_faculty_survey_email]
  before_action :set_units, only: %i[ index new create edit update ]
  before_action :set_terms, only: %i[ new create edit update ]
  include ConfigQuestionsHelper

  # GET /faculty_surveys or /faculty_surveys.json
  def index
    @terms = Term.sorted
    if params[:unit_id].present?
      @faculty_surveys = FacultySurvey.where(unit_id: params[:unit_id])
    else
      @faculty_surveys = FacultySurvey.where(unit_id: @units)
    end
    @faculty_surveys = @faculty_surveys.data(params[:term_id]).order(created_at: :desc)
    authorize @faculty_surveys
  end

  def surveys_index
    @surveys_list = FacultySurvey.where(uniqname: current_user.uniqname).order(created_at: :desc)
    authorize @surveys_list
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
    uniqname = faculty_survey_params[:uniqname]
    result = get_faculty_name_for_survey(uniqname)
    if result['valid']
      @faculty_survey['first_name'] = result['first_name']
      @faculty_survey['last_name'] = result['last_name']
    else
      flash.now[:alert] = result['note']
      return
    end
    if @faculty_survey.save
      add_config_questions(@faculty_survey)
      if result['note'].include?("Mcommunity returns no name")
        redirect_to edit_faculty_survey_path(@faculty_survey), notice: "Faculty survey was successfully created." + result['note'] + " Add first and last name manually."
      else
        redirect_to faculty_survey_config_questions_path(@faculty_survey), notice: "Faculty survey was successfully created." + result['note'] + " You can edit the questions and send an email to the instructor."
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /faculty_surveys/1 or /faculty_surveys/1.json
  def update
    @faculty_survey.attributes = faculty_survey_params
    if @faculty_survey.uniqname_changed?
      result = get_faculty_name_for_survey(@faculty_survey.uniqname)
      if result['valid']
        @faculty_survey['first_name'] = result['first_name']
        @faculty_survey['last_name'] = result['last_name']
      else
        flash.now[:alert] = result['note']
        return
      end
    end
    if @faculty_survey.save
      redirect_to faculty_surveys_path(:term_id => @faculty_survey.term_id), notice: "Faculty survey was successfully updated. Click on Survey Questions to edit the questions and send an email to instructor."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def send_faculty_survey_email
    FacultyMailer.with(faculty_survey: @faculty_survey, user: current_user).send_faculty_survey.deliver_now
    @email_log_entries = EmailLog.where(sent_from_model: "FacultySurvey", record_id: @faculty_survey.id).order(created_at: :desc)
    redirect_to faculty_survey_config_questions_path(@faculty_survey), notice: 'Email was sent'
  end

  # DELETE /faculty_surveys/1 or /faculty_surveys/1.json
  def destroy
    @faculty_survey.destroy
    flash.now[:notice] = "Program survey was successfully deleted."
    if params[:unit_id].present?
      @faculty_surveys = FacultySurvey.where(unit_id: params[:unit_id])
    else
      @faculty_surveys = FacultySurvey.where(unit_id: @units)
    end
    @faculty_surveys = @faculty_surveys.data(params[:term_id]).order(created_at: :desc)
    authorize @faculty_surveys
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

    def set_units
      @units = []
      current_user.unit_ids.each do |unit_id|
        if unit_use_faculty_survey?(unit_id)
          @units << Unit.find(unit_id)
        end
      end
    end

    def set_terms
      @terms = Term.current_and_future
    end

    # Only allow a list of trusted parameters through.
    def faculty_survey_params
      params.require(:faculty_survey).permit(:title, :uniqname, :term_id, :unit_id, :first_name, :last_name)
    end
end
