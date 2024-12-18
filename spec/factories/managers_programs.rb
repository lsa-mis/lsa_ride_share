# == Schema Information
#
# Table name: managers_programs
#
#  id         :bigint           not null, primary key
#  manager_id :bigint
#  program_id :bigint
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :managers_program do
    
  end
end
