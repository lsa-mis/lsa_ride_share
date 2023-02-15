# == Schema Information
#
# Table name: reservations
#
#  id                       :bigint           not null, primary key
#  status                   :string
#  program_id               :bigint           not null
#  site_id                  :bigint           not null
#  car_id                   :bigint
#  start_date               :datetime
#  end_date                 :datetime
#  recurring                :string
#  driver_id                :bigint
#  driver_phone             :string
#  backup_driver_id         :bigint
#  backup_driver_phone      :string
#  number_of_people_on_trip :integer
#  updated_by               :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
class Reservation < ApplicationRecord
  belongs_to :program
  belongs_to :site
  belongs_to :car, optional: true
  belongs_to :driver, optional: true, class_name: 'Student', foreign_key: :driver_id
  belongs_to :backup_driver, optional: true, class_name: 'Student', foreign_key: :backup_driver_id
  has_many :reservation_passengers
  has_many :passengers, through: :reservation_passengers, source: :student
  has_one :vehicle_report
  
  has_rich_text :note

  scope :with_passengers, -> { Reservation.includes(:passengers) }

end
