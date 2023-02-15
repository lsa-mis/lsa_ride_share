# == Schema Information
#
# Table name: vehicle_reports
#
#  id             :bigint           not null, primary key
#  reservation_id :bigint           not null
#  mileage_start  :float
#  mileage_end    :float
#  gas_start      :float
#  gas_end        :float
#  parking_spot   :string
#  created_by     :integer
#  updated_by     :integer
#  status         :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
require 'rails_helper'

RSpec.describe VehicleReport, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
