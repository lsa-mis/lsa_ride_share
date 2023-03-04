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
  has_and_belongs_to_many :programs
  has_many :reservations
  has_rich_text :note

  def address
    "#{self.address1} #{self.address2} #{self.city} #{self.state} #{self.zip_code}"
  end
  
end
