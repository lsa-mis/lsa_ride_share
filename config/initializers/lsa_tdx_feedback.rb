Rails.application.reloader.to_prepare do
  LsaTdxFeedback::FeedbackController.class_eval do
    skip_before_action :authorize_feedback, raise: false
    before_action :authorize_feedback, only: :create

    private
    
    def authorize_feedback
      authorize :feedback
    end
  end
end
