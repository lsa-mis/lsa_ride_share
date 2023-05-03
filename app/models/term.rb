# == Schema Information
#
# Table name: terms
#
#  id                 :bigint           not null, primary key
#  code               :string
#  name               :string
#  classes_begin_date :date
#  classes_end_date   :date
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
class Term < ApplicationRecord
  has_many :faculty_surveys

  validates_presence_of :code, :name, :classes_begin_date, :classes_end_date

  scope :sorted, -> { where.not(classes_begin_date: nil).order(:classes_begin_date, classes_end_date: :desc) }
  scope :current, -> { sorted.where(':date BETWEEN classes_begin_date AND classes_end_date', date: Date.today) }
  scope :future, -> { sorted.where('classes_begin_date > :date', date: Date.today)}
  scope :current_and_future, -> { current + future }

end
