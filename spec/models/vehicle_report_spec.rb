# == Schema Information
#
# Table name: vehicle_reports
#
#  id                  :bigint           not null, primary key
#  reservation_id      :bigint           not null
#  mileage_start       :float
#  mileage_end         :float
#  gas_start           :decimal(, )
#  gas_end             :decimal(, )
#  parking_spot        :string
#  created_by          :integer
#  updated_by          :integer
#  status              :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  student_status      :boolean          default(FALSE)
#  approved            :boolean          default(FALSE)
#  parking_spot_return :string
#  parking_notes       :text
#
require 'rails_helper'

RSpec.describe VehicleReport, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
