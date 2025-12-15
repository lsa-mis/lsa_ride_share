# == Schema Information
#
# Table name: import_reservation_logs
#
#  id         :bigint           not null, primary key
#  date       :datetime
#  user       :string
#  unit_id    :integer
#  status     :string
#  note       :string           default([]), is an Array
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'rails_helper'

RSpec.describe ImportReservationLog, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
