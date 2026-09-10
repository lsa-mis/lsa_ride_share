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
class Car < ApplicationRecord
  belongs_to :unit
  has_many :reservations
  has_many :vehicle_reports, dependent: :restrict_with_exception
  has_many :notes, as: :noteable
  has_many_attached :initial_damages do |attachable|
    attachable.variant :thumb, resize_to_limit: [640, 480]
  end
  include AppendToHasManyAttached['initial_damages']

  validates_presence_of :car_number, :make, :model, :color, :number_of_seats, :mileage, :gas, :parking_spot, :status, :updated_by
  validates :car_number, uniqueness: { scope: :unit_id, message: "must be unique within the same unit" }
  validate :acceptable_image
  validates_numericality_of :mileage, greater_than: 0, message: 'must be positive'
  
  enum :status, [:available, :unavailable], prefix: true, scopes: true

  scope :data, ->(unit_id) { unit_id.present? ? where(unit_id: unit_id) : all }
  scope :available, -> { where(status: 'available') }
  scope :unavailable_with_reservations_for_unit_on, ->(unit_id, day) {
    where(status: 'unavailable', unit_id: unit_id)
      .joins(:reservations)
      .where(reservations: {
        start_time: day.beginning_of_day..day.end_of_day
      })
      .distinct
    }

  def reservations_past
    self.reservations.includes(:site, :vehicle_report, program: [:term, :courses]).where('start_time <= ?', Time.current).order(start_time: :desc)
  end

  def reservations_future
    self.reservations.includes(:site, :vehicle_report, program: [:term, :courses]).where('start_time > ?', Time.current).order(start_time: :asc)
  end

  def last_vehicle_report
    reservation_vehicle_reports.max_by(&:updated_at)
  end

  def vehicle_reports_ids
    ids = reservation_vehicle_reports.map(&:id)
    ids.present? ? ids.join(",") : []
  end

  def vehicle_reports
    reservation_vehicle_reports.sort_by(&:updated_at).reverse
  end

  # Uses the loaded reservations/vehicle_report associations to avoid N+1 queries
  def reservation_vehicle_reports
    res = reservations
    res = res.includes(:vehicle_report) unless res.loaded?
    res.filter_map(&:vehicle_report)
  end

  def acceptable_image
    return unless initial_damages.attached?

    acceptable_types = ["image/jpg", 
    "image/jpeg",
    "image/png",
    "image/heic"]
    
    initial_damages.each do |image|
      unless image.blob.byte_size <= 10.megabyte
        errors.add(:base, "the image is too big")
      end

      unless acceptable_types.include?(image.content_type)
        errors.add(:base, "the image has incorrect file type")
      end
    end
  end

end
