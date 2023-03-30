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
  
  scope :current, -> { where(':date BETWEEN term_start AND term_end', date: Date.today)}

end
