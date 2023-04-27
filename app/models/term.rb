# == Schema Information
#
# Table name: terms
#
#  id         :bigint           not null, primary key
#  code       :string
#  name       :string
#  term_start :date
#  term_end   :date
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Term < ApplicationRecord

  validates_presence_of :code, :name, :term_start, :term_end

  scope :sorted, -> { where.not(term_start: nil).order(:term_start, term_end: :desc) }
  scope :between_start_and_end_dates, -> { sorted.where(':date BETWEEN term_start AND term_end', date: Date.today) }
  scope :started_before_today, -> { sorted.where('term_start < :date', date: Date.today) }
  scope :max_started_before_today, -> { sorted.where(term_start: started_before_today.max.term_start) }
  scope :current, -> { between_start_and_end_dates.or(max_started_before_today) }

end
