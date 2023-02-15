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
class VehicleReport < ApplicationRecord
  belongs_to :reservation

  has_one_attached :image_front_start
  has_one_attached :image_driver_start
  has_one_attached :image_passenger_start
  has_one_attached :image_back_start
  has_one_attached :image_front_end
  has_one_attached :image_driver_end
  has_one_attached :image_passenger_end
  has_one_attached :image_back_end
  has_rich_text :note

  def car
    self.reservation.car
  end

  def program
    self.reservation.program
  end

  def site
    self.reservation.site
  end

  def driver
    self.reservation.driver
  end

end
