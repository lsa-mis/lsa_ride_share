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
#  last_checked    :datetime
#  last_driver     :integer
#  updated_by      :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  status          :string
#
class Car < ApplicationRecord
  has_and_belongs_to_many :programs
  has_many :reservations
  has_rich_text :note
  has_many_attached :initial_damages do |attachable|
    attachable.variant :thumb, resize_to_limit: [640, 480]
  end
  include AppendToHasManyAttached['initial_damages']

  validates_presence_of :car_number, :make, :model, :color, :number_of_seats, :mileage, :gas, :parking_spot

  def last_vehicle_report
    VehicleReport.where(reservation_id: self.reservations.ids).present? ?
    VehicleReport.where(reservation_id: self.reservations.ids).order(:updated_at).last :
    nil
  end

  def vehicle_reports_ids
    VehicleReport.where(reservation_id: self.reservations.ids).present? ? 
      VehicleReport.where(reservation_id: self.reservations.ids).pluck(:id).join(",") : 
      []
  end

end
