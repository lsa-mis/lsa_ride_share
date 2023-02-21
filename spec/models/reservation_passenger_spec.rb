# == Schema Information
#
# Table name: reservation_passengers
#
#  id             :bigint           not null, primary key
#  reservation_id :bigint           not null
#  student_id     :bigint           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
require 'rails_helper'

RSpec.describe ReservationPassenger, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
