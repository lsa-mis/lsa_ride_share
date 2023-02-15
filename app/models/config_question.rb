# == Schema Information
#
# Table name: config_questions
#
#  id         :bigint           not null, primary key
#  program_id :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class ConfigQuestion < ApplicationRecord
  belongs_to :program

  has_rich_text :question
  has_rich_text :answer
end
