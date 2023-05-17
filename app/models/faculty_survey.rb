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
#  first_name :string
#  last_name  :string
#  title      :string
#

class FacultySurvey < ApplicationRecord
  has_many :config_questions
  belongs_to :term
  belongs_to :unit

  validates_presence_of :title, :uniqname, :term_id, :unit_id

  scope :current_term, -> { where(term_id: Term.current) }
  scope :data, ->(term_id) { term_id.present? ? where(term_id: term_id) : current_term }

  def display_name
    "#{self.term.name} - #{self.unit.name} - #{instructor}"
  end

  def instructor
    "#{self.first_name} #{self.last_name} - #{uniqname}"
  end

end
