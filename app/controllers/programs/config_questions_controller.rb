class Programs::ConfigQuestionsController < ConfigQuestionsController
  before_action :set_config_question_program

  private

  def set_config_question_program
      @config_question_program = Program.find(params[:program_id])
  end

end