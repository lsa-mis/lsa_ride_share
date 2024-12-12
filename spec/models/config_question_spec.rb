# == Schema Information
#
# Table name: config_questions
#
#  id                :bigint           not null, primary key
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  faculty_survey_id :bigint
#
require 'rails_helper'

RSpec.describe ConfigQuestion, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
