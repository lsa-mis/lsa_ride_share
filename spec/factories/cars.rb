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
#  gas             :float
#  parking_spot    :string
#  last_used       :datetime
#  last_driver     :integer
#  updated_by      :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  status          :integer
#
FactoryBot.define do
  factory :car do
    car_number { "MyString" }
    make { "MyString" }
    model { "MyString" }
    color { "MyString" }
    number_of_seats { 1 }
    mileage { 1.5 }
    gas { 1.5 }
    parking_spot { "MyString" }
    last_used { "2023-02-14 19:16:18" }
    last_checked { "2023-02-14 19:16:18" }
    last_driver { 1 }
  end
end
