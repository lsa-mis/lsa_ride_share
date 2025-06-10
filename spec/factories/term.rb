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
    code { "2540" }
    name { "Current Term" }
    classes_begin_date { DateTime.now - 4.day }
    classes_end_date { DateTime.now + 4.day }
  end
end
