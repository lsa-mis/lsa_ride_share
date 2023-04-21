# == Schema Information
#
# Table name: faculty_surveys
#
#  id         :bigint           not null, primary key
#  uniqname   :string
#  term_id    :bigint
#  unit_id    :bigint
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  program_id :integer
#

class FacultySurvey < ApplicationRecord
  has_many :config_questions
  belongs_to :term
  belongs_to :unit

  def display_name
    "#{self.term.name} - #{self.unit.name} - #{uniqname}"
  end

end
