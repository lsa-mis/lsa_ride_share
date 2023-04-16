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
#
class Site < ApplicationRecord
  has_many :programs_sites
  has_many :programs, through: :programs_sites
  has_many :reservations
  has_many :site_contacts
  has_many :notes, as: :noteable

  def address
    "#{self.address1} #{self.address2} #{self.city} #{self.state} #{self.zip_code}"
  end
end
