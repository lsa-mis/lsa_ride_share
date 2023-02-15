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
require 'rails_helper'

RSpec.describe AdminAccess, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
