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
#  parking_note        :text
#  parking_note_return :text
#
FactoryBot.define do
  factory :vehicle_report do
    mileage_start { Faker::Vehicle.mileage }
    mileage_end { Faker::Vehicle.mileage }
    gas_start { 62.5 }
    gas_end { 62.5 }
    parking_spot { Faker::Lorem.word }
    created_by { FactoryBot.create(:user).id }
    updated_by { FactoryBot.create(:user).id }
    association :reservation
  end
end
