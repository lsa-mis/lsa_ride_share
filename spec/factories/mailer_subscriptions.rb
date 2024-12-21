# == Schema Information
#
# Table name: mailer_subscriptions
#
#  id           :bigint           not null, primary key
#  user_id      :bigint           not null
#  unsubscribed :boolean
#  mailer       :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
FactoryBot.define do
  factory :mailer_subscription do
    unsubscribed { true }
    mailer { "one_hour_reminder" }
    association :user
  end
end
