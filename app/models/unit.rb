# == Schema Information
#
# Table name: units
#
#  id         :bigint           not null, primary key
#  name       :string
#  ldap_group :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Unit < ApplicationRecord
  has_many :programs
  has_many :cars
  has_many :unit_preferences, dependent: :destroy
  has_many :faculty_surveys
  
  validates_presence_of :name, :ldap_group
  validates :name, :ldap_group, uniqueness: { case_sensitive: false }

end
