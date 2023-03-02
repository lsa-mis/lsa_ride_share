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
require 'rails_helper'

RSpec.describe Term, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
