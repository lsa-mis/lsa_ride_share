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
#  unit_id    :bigint
#
class Site < ApplicationRecord
  has_many :programs_sites
  has_many :programs, through: :programs_sites
  has_many :reservations
  has_many :contacts, dependent: :destroy
  has_many :notes, as: :noteable
  belongs_to :unit

  accepts_nested_attributes_for :contacts
  validates_presence_of :title, :address1, :city, :state
  validates :zip_code, presence: true, format: { with: /\A\d{5}(-\d{4})?\z/, message: "should be in the form 12345 or 12345-1234"}
  validates :title, uniqueness: { case_sensitive: false, scope: [:unit_id], message: "already exist" }

  def address
    "#{self.address1} #{self.address2} #{self.city} #{self.state} #{self.zip_code}"
  end
end
