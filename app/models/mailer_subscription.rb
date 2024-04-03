# == Schema Information
#
# Table name: mailer_subscriptions
#
#  id               :bigint           not null, primary key
#  user_id          :bigint           not null
#  mailer           :string           not null
#  unsubscribed       :boolean
#  created_at      :datetime          not null
#  updated_at      :datetime          not null
# 

class MailerSubscription < ApplicationRecord
  belongs_to :user

  MAILERS =
    OpenStruct.new(
      items: [
        {
          class: "ReservationMailer",
          name: "one_hour_reminder",
          description: "Remind drivers about next hour reservation.",
        },
        {
          class: "ReservationMailer",
          name: "vehicle_report_reminder",
          description: "Remind drivers to complete vehicle reports.",
        },
      ],
    ).freeze

  validates :unsubscribed, inclusion: [true, false], allow_nil: true
  validates :mailer, presence: true
  validates :mailer, inclusion: MAILERS.items.map { |item| item[:name] }
  validates :user, uniqueness: { scope: :mailer }

  # @mailer_subscription.details
  # => [{:class => "ReservationMailer", :name => "Reservation Reminder Emails", :description => "Remind drivers about next hour reservation."}]
  def details
    MailerSubscription::MAILERS.items.select { |item| item[:name] == mailer }
  end

  # @mailer_subscription.name
  # => "Reservation Reminder Emails"
  def name
    details[0][:name]
  end

  def description
    details[0][:description]
  end

  # @mailer_subscription.action
  # => "Subscribe to"
  def action
    unsubscribed? ? "Subscribe to:" : "Unsubscribe from:"
  end

  # @mailer_subscription.call_to_action
  # => "Subscribe to Reservation Reminder Emails"
  def call_to_action
    "#{action}"
  end

end
