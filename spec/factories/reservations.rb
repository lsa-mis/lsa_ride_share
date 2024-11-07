# == Schema Information
#
# Table name: reservations
#
#  id                       :bigint           not null, primary key
#  status                   :string
#  program_id               :bigint           not null
#  site_id                  :bigint           not null
#  car_id                   :bigint
#  start_time               :datetime
#  end_time                 :datetime
#  recurring                :text
#  driver_id                :bigint
#  driver_phone             :string
#  backup_driver_id         :bigint
#  backup_driver_phone      :string
#  number_of_people_on_trip :integer
#  updated_by               :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  reserved_by              :integer
#  approved                 :boolean          default false
#  non_uofm_passengers      :string
#  number_of_non_uofm_passengers :integer
#  driver_manager_id        :bigint
#  prev                     :bigint
#  next                     :bigint
#  until_date               :date
#

FactoryBot.define do
  factory :reservation do
    start_time { DateTime.now }
    end_time { DateTime.now + 4.hour }
    recurring { "" }
    number_of_people_on_trip { 3 }
    updated_by { FactoryBot.create(:user).id }
    reserved_by { FactoryBot.create(:user).id }
    association :program
    association :site
    association :car
  end
end
