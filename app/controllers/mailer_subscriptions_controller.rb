class MailerSubscriptionsController < ApplicationController
  before_action :auth_user
	before_action :set_mailer_subscription, only: :update

	def index
    @mailer_subscriptions = MailerSubscription::MAILERS.items.map do |item|
      MailerSubscription.find_or_initialize_by(mailer: item[:name], user: current_user)
    end
    authorize MailerSubscription
  end

  def create
    @mailer_subscription = MailerSubscription.new
    mailer = mailer_subscription_params['mailer']
    @mailer_subscription.unsubscribed = params[mailer]['unsubscribed']
    @mailer_subscription.mailer = mailer
    @mailer_subscription.user_id = current_user.id
    if @mailer_subscription.save
      redirect_to mailer_subscriptions_path, notice: "Preferences updated."
    else
      redirect_to mailer_subscriptions_path, alter: "#{@mailer_subscription.errors.full_messages.to_sentence}"
    end
    authorize @mailer_subscription
  end

  def update
    authorize @mailer_subscription
    if @mailer_subscription.toggle!(:unsubscribed)
      redirect_to mailer_subscriptions_path, notice: "Preferences updated."
    else
      redirect_to mailer_subscriptions_path, alter: "#{@mailer_subscription.errors.full_messages.to_sentence}"
    end
  end

	private

    def mailer_subscription_params
      params.require(:mailer_subscription).permit(:mailer)
    end

    def set_mailer_subscription
      @mailer_subscription = MailerSubscription.find(params[:id])
    end

end
