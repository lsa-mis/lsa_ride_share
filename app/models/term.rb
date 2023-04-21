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

  scope :sorted, -> { order(:term_start, term_end: :desc) }
  scope :current, -> { all.where(':date BETWEEN term_start AND term_end', date: Date.today).or(all.where(term_start: all.where('term_start < :date', date: Date.today).max.term_start)) }

end
