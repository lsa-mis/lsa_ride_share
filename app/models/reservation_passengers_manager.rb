# == Schema Information
#
# Table name: reservation_passengers_managers
#
#  id             :bigint           not null, primary key
#  reservation_id :bigint           not null
#  manager_id     :bigint           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class ReservationPassengersManager < ApplicationRecord
  belongs_to :reservation
  belongs_to :manager
end
