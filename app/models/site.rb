# == Schema Information
#
# Table name: sites
#
#  id         :bigint           not null, primary key
#  title      :string
#  address1   :string
#  address2   :string
#  city       :string
#  state      :string
#  zip_code   :string
#  updated_by :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  unit_id    :bigint           not_null
#
class Site < ApplicationRecord
  has_many :programs_sites
  has_many :programs, through: :programs_sites
  has_many :reservations
  has_many :site_contacts, dependent: :destroy
  has_many :notes, as: :noteable

  accepts_nested_attributes_for :site_contacts
  validates_presence_of :title, :address1, :address2, :city, :state
  validates :zip_code, presence: true, format: { with: /\d{5}(-\d{4})?/, message: "should be in the form 12345 or 12345-1234"}

  def address
    "#{self.address1} #{self.address2} #{self.city} #{self.state} #{self.zip_code}"
  end
end
