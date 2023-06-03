# == Schema Information
#
# Table name: unit_preferences
#
#  id          :bigint           not null, primary key
#  name        :string
#  description :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  on_off      :boolean
#  value       :string
#  pref_type   :integer
#  unit_id     :bigint
#

class UnitPreference < ApplicationRecord
  belongs_to :unit

  enum :pref_type, [:boolean, :string, :time], prefix: true, scopes: true

  validates :name, uniqueness: { scope: :unit_id, message: "should be unique." }
  validates_presence_of :pref_type

  def name=(value)
    super(value.try(:strip))
  end
end
