# == Schema Information
#
# Table name: config_questions
#
#  id                :bigint           not null, primary key
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  faculty_survey_id :bigint
#

class ConfigQuestion < ApplicationRecord
  belongs_to :faculty_survey

  has_rich_text :question
  has_rich_text :answer

  validates :question, presence: true
end
