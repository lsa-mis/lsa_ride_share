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
end
