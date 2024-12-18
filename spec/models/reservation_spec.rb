# == Schema Information
#
# Table name: reservations
#
#  id                            :bigint           not null, primary key
#  status                        :string
#  program_id                    :bigint           not null
#  site_id                       :bigint           not null
#  car_id                        :bigint
#  start_time                    :datetime
#  end_time                      :datetime
#  recurring                     :text
#  driver_id                     :bigint
#  driver_phone                  :string
#  backup_driver_id              :bigint
#  backup_driver_phone           :string
#  number_of_people_on_trip      :integer
#  updated_by                    :integer
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  reserved_by                   :integer
#  approved                      :boolean          default(FALSE)
#  non_uofm_passengers           :string
#  number_of_non_uofm_passengers :integer          default(0)
#  driver_manager_id             :bigint
#  prev                          :integer
#  next                          :integer
#  until_date                    :date
#
require 'rails_helper'

RSpec.describe Reservation, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
