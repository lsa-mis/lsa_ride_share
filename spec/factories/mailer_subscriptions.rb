FactoryBot.define do
  factory :mailer_subscription do
    user { nil }
    subscribed { false }
    mailer { "MyString" }
  end
end
