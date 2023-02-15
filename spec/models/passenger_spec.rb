# == Schema Information
#
# Table name: passengers
#
#  id             :bigint           not null, primary key
#  reservation_id :bigint           not null
#  student_id     :bigint           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
require 'rails_helper'

RSpec.describe Passenger, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
