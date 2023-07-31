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
#  gas             :decimal
#  parking_spot    :string
#  last_used       :datetime
#  last_driver     :integer
#  updated_by      :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  status          :integer
#  unit_id         :bigint
#
class Car < ApplicationRecord
  belongs_to :unit
  has_many :reservations
  has_many :notes, as: :noteable
  has_many_attached :initial_damages do |attachable|
    attachable.variant :thumb, resize_to_limit: [640, 480]
  end
  include AppendToHasManyAttached['initial_damages']

  validates_presence_of :car_number, :make, :model, :color, :number_of_seats, :mileage, :gas, :parking_spot, :status, :updated_by
  validate :acceptable_image
  validates_numericality_of :gas, greater_than: 0, less_than_or_equal_to: 100, message: 'must be between 0 & 100'
  validates_numericality_of :mileage, greater_than: 0, message: 'must be positive'
  
  enum :status, [:available, :unavailable], prefix: true, scopes: true

  scope :data, ->(unit_id) { unit_id.present? ? where(unit_id: unit_id) : all }
  scope :available, -> { where(status: 'available') }

  def reservations_past
    self.reservations.where('start_time <= ?', DateTime.now).sort_by(&:start_time).reverse
  end

  def reservations_future
    self.reservations.where('start_time > ?', DateTime.now).sort_by(&:start_time)
  end

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

  def vehicle_reports
    VehicleReport.where(reservation_id: self.reservations.ids).order(updated_at: :desc)
  end

  def acceptable_image
    return unless initial_damages.attached?

    acceptable_types = ["image/png", "image/jpeg"]
    
    initial_damages.each do |image|
      unless image.blob.byte_size <= 10.megabyte
        errors.add(image.name, "is too big")
      end

      unless acceptable_types.include?(image.content_type)
        errors.add(image.name, "incorrect file type")
      end
    end
  end

end
