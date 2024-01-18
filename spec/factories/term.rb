# == Schema Information
#
# Table name: terms
#
#  id                 :bigint           not null, primary key
#  code               :string
#  name               :string
#  classes_begin_date :date
#  classes_end_date   :date
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

FactoryBot.define do
  factory :term do
    code { "2470" }
    name { "Winter 2024" }
    classes_begin_date { "2024-01-10" }
    classes_end_date { "2024-05-06" }
  end
end
