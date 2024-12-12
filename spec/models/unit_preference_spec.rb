# == Schema Information
#
# Table name: unit_preferences
#
#  id          :bigint           not null, primary key
#  name        :string
#  description :string
#  on_off      :boolean
#  unit_id     :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  value       :string
#  pref_type   :integer
#
require 'rails_helper'

RSpec.describe UnitPreference, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
