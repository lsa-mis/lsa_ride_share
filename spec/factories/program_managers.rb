# == Schema Information
#
# Table name: program_managers
#
#  id         :bigint           not null, primary key
#  uniqname   :string
#  first_name :string
#  last_name  :string
#  updated_by :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  program_id :bigint
#
FactoryBot.define do
  factory :program_manager do
    uniqname { "MyString" }
    first_name { "MyString" }
    last_name { "MyString" }
  end
end
