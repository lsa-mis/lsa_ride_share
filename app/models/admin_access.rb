# == Schema Information
#
# Table name: admin_accesses
#
#  id         :bigint           not null, primary key
#  department :string
#  ldap_group :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class AdminAccess < ApplicationRecord
  has_many :programs
end
