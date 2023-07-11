FactoryBot.define do
  factory :email_log do
    sent_from { "MyString" }
    record_id { 1 }
    email_type { "MyString" }
    sent_by { 1 }
    sent_at { "2023-07-07 14:58:16" }
  end
end
