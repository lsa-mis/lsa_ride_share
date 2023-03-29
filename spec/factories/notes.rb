# == Schema Information
#
# Table name: notes
#
#  id            :bigint           not null, primary key
#  user_id       :bigint           not null
#  noteable_type :string           not null
#  noteable_id   :bigint           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
FactoryBot.define do
  factory :note do
    
  end
end
