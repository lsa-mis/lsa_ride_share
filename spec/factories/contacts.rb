# == Schema Information
#
# Table name: contacts
#
#  id           :bigint           not null, primary key
#  title        :string
#  first_name   :string
#  last_name    :string
#  phone_number :string
#  email        :string
#  site_id      :bigint           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

FactoryBot.define do
  factory :contact do
    title { Faker::Educator.subject }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    phone_number { "509-591-4724" }
    email { Faker::Internet.email }
    association :site
  end
end
