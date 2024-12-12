# == Schema Information
#
# Table name: email_logs
#
#  id              :bigint           not null, primary key
#  sent_from_model :string
#  record_id       :integer
#  email_type      :string
#  sent_to         :string
#  sent_by         :integer
#  sent_at         :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
FactoryBot.define do
  factory :email_log do
    sent_from { "MyString" }
    record_id { 1 }
    email_type { "MyString" }
    sent_by { 1 }
    sent_at { "2023-07-07 14:58:16" }
  end
end
