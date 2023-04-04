# == Schema Information
#
# Table name: unit_preferences
#
#  id          :bigint           not null, primary key
#  name        :string
#  description :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  value       :boolean
#  unit_id     :bigint
#

class UnitPreference < ApplicationRecord
  belongs_to :unit
end
