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

class UnitPreference < ApplicationRecord
  belongs_to :unit

  enum :pref_type, [:boolean, :integer, :string, :time], prefix: true, scopes: true

  validates :name, uniqueness: { scope: :unit_id, message: "should be unique." }
  validates_presence_of :pref_type, :description

  def name=(value)
    super(value.try(:strip))
  end
end
