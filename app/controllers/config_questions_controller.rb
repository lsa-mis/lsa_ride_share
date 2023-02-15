class ConfigQuestionsController < ApplicationController
  before_action :set_config_question, only: %i[ show edit update destroy ]

  # GET /config_questions or /config_questions.json
  def index
    @config_questions = ConfigQuestion.all
  end

  # GET /config_questions/1 or /config_questions/1.json
  def show
  end

  # GET /config_questions/new
  def new
    @config_question = ConfigQuestion.new
  end

  # GET /config_questions/1/edit
  def edit
  end

  # POST /config_questions or /config_questions.json
  def create
    @config_question = ConfigQuestion.new(config_question_params)

    respond_to do |format|
      if @config_question.save
        format.html { redirect_to config_question_url(@config_question), notice: "Config question was successfully created." }
        format.json { render :show, status: :created, location: @config_question }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @config_question.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /config_questions/1 or /config_questions/1.json
  def update
    respond_to do |format|
      if @config_question.update(config_question_params)
        format.html { redirect_to config_question_url(@config_question), notice: "Config question was successfully updated." }
        format.json { render :show, status: :ok, location: @config_question }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @config_question.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /config_questions/1 or /config_questions/1.json
  def destroy
    @config_question.destroy

    respond_to do |format|
      format.html { redirect_to config_questions_url, notice: "Config question was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_config_question
      @config_question = ConfigQuestion.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def config_question_params
      params.require(:config_question).permit(:program_id)
    end
end
