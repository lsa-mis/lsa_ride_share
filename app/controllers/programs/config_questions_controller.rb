class Programs::ConfigQuestionsController < ApplicationController
  before_action :set_config_question_program

  def index
    @config_questions = @config_question_program.config_questions.order(:id)
  end

  def new
    @config_question = ConfigQuestion.new
  end

  def create
    @config_question = ConfigQuestion.new(config_question_params)
    @config_question.program_id = params[:program_id]

    respond_to do |format|
      if @config_question.save
        @config_question_program.config_questions << @config_question
        format.turbo_stream { redirect_to program_config_questions_path(@config_question_program), 
                              notice: "The config_question was added" 
                            }
      else
        format.turbo_stream { redirect_to @config_question_program, 
          alert: "Fail: you need to enter a config_question data" 
        }
      end
    end
  end

  def edit
    @config_question = ConfigQuestion.find(params[:id])
  end

  def update
    @config_question = ConfigQuestion.find(params[:id])

    respond_to do |format|
      if @config_question.update(config_question_params)
        format.turbo_stream { redirect_to program_config_questions_path(@config_question_program),
                              notice: "The config_question was added" 
                            }
      else
        format.turbo_stream { redirect_to @config_question_program, 
          alert: "Fail" 
        }
      end
    end

  end

  def destroy
    @config_question = ConfigQuestion.find(params[:id])

    @config_question.destroy

    respond_to do |format|
      format.turbo_stream { redirect_to program_config_questions_path(@config_question_program), 
                              notice: "The config_question was deleted" 
                            }
    end
  end

  private

  def set_config_question_program
      @config_question_program = Program.find(params[:program_id])
  end

  def config_question_params
    params.require(:config_question).permit(:program_id, :question)
  end

end