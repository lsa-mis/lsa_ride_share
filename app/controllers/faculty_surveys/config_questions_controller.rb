class FacultySurveys::ConfigQuestionsController < ApplicationController
  before_action :auth_user
  before_action :set_faculty_survey
  before_action :set_config_question, only: %i[ edit update destroy ]

  def index
    config_questions = @faculty_survey.config_questions.order(:id)
    @config_questions_no_edit = config_questions[0..5]
    @config_questions_edit = config_questions.drop(6)
    @email_log_entries = EmailLog.where(sent_from_model: "FacultySurvey", record_id: @faculty_survey.id).order(created_at: :desc)
    authorize config_questions
  end

  def new
    @config_question = ConfigQuestion.new
    authorize @config_question
  end

  def create
    @config_question = ConfigQuestion.new(config_question_params)
    authorize @config_question
    if @config_question.save
      @faculty_survey.config_questions << @config_question
      redirect_to faculty_survey_config_questions_path(@faculty_survey), notice: "New question was added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @config_question.update(config_question_params)
      redirect_to faculty_survey_config_questions_path(@faculty_survey), notice: "Question was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @config_question.destroy
      flash.now[:notice] = "Question was deleted."
    end
    index
  end

  def survey
    new_survey = Survey.new(@faculty_survey)
    @survey = new_survey.questions_to_display
    authorize new_survey
  end

  def save_survey
    new_survey = Survey.new(@faculty_survey)
    authorize new_survey
    result = new_survey.update_answers(params[:survey])
    unless result['success']
      redirect_to survey_path(@faculty_survey), alert: result['note']
      return
    end
    unless @faculty_survey.program_id.present?
      program_id = new_survey.create_program_from_survey(current_user)
      if program_id
        @faculty_survey.update(program_id: program_id)
        # send email to the admin that the proram was created
        FacultyMailer.with(faculty_survey: @faculty_survey, user: current_user).faculty_survey_program_created.deliver_now
        # send confirmation email to faculty that the survey was submitted
        FacultyMailer.with(faculty_survey: @faculty_survey, user: current_user).faculty_survey_confirmation.deliver_now
      else
        redirect_to surveys_index_path, alert: "Error creating program from the survey. Please report an issue."
        return
      end
    end
    redirect_to faculty_survey_config_questions_path(@faculty_survey), notice: "The survey answers are updated."
  end

  private

    def set_faculty_survey
      @faculty_survey = FacultySurvey.find(params[:faculty_survey_id])
    end

    def set_config_question
      @config_question = ConfigQuestion.find(params[:id])
      authorize @config_question
    end

    def config_question_params
      params.require(:config_question).permit(:faculty_survey_id, :question)
    end

end
