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
#  status          :string
#
require 'rails_helper'

RSpec.describe Car, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
