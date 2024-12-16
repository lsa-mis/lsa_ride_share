# == Schema Information
#
# Table name: cars
#
#  id              :bigint           not null, primary key
#  car_number      :string
#  make            :string
#  model           :string
#  color           :string
#  number_of_seats :integer
#  mileage         :float
#  gas             :decimal(, )
#  parking_spot    :string
#  last_used       :datetime
#  last_driver_id  :integer
#  updated_by      :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  status          :integer
#  unit_id         :bigint
#  parking_note    :text
#

FactoryBot.define do
  factory :car do
    car_number { "#{Faker::Vehicle.car_type} - #{Faker::Number.number(digits: 3)}" }
    make { Faker::Vehicle.make }
    model { Faker::Vehicle.model}
    color { Faker::Vehicle.color }
    number_of_seats { Faker::Number.within(range: 1..7) }
    mileage { Faker::Vehicle.mileage }
    gas { 62.5 }
    parking_spot { Faker::Lorem.word }
    last_used { Faker::Date.in_date_period }
    # last_driver_id nil
    updated_by { FactoryBot.create(:user).id }
    status { Faker::Number.within(range: 0..1) }
    association :unit
  end
end
