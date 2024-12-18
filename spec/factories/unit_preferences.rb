# == Schema Information
#
# Table name: unit_preferences
#
#  id          :bigint           not null, primary key
#  name        :string
#  description :string
#  on_off      :boolean
#  unit_id     :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  value       :string
#  pref_type   :integer
#
FactoryBot.define do
  factory :unit_preference do
    name { "MyString" }
    description { "MyString" }
    value { false }
    unit { nil }
  end
end
