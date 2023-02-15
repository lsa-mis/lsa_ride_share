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
FactoryBot.define do
  factory :vehicle_report do
    reservation { nil }
    mileage_start { 1.5 }
    mileage_end { 1.5 }
    gas_start { 1.5 }
    gas_end { 1.5 }
    parking_spot { "MyString" }
    created_by { 1 }
    updated_by { 1 }
    status { "MyString" }
  end
end
