class FacultySurveys::ConfigQuestionsController < ApplicationController
  before_action :set_faculty_survey

  def index
    @config_questions = @faculty_survey.config_questions.order(:id)
    authorize @config_questions
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
    @config_question = ConfigQuestion.find(params[:id])
    authorize @config_question
  end

  def update
    @config_question = ConfigQuestion.find(params[:id])
    authorize @config_question
    if @config_question.update(config_question_params)
      redirect_to faculty_survey_config_questions_path(@faculty_survey), notice: "Question was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @config_question = @faculty_survey.config_questions.find(params[:id])
    authorize @config_question

    if @config_question.destroy
      flash.now[:notice] =  "Question was deleted."
    end
    @config_questions = @faculty_survey.config_questions.order(:id)

  end

  private

  def set_faculty_survey
    @faculty_survey = FacultySurvey.find(params[:faculty_survey_id])
  end

  def config_question_params
    params.require(:config_question).permit(:faculty_survey_id, :question)
  end

end
