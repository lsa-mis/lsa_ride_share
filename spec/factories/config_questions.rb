# == Schema Information
#
# Table name: config_questions
#
#  id         :bigint           not null, primary key
#  program_id :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :config_question do
    program { nil }
  end
end
