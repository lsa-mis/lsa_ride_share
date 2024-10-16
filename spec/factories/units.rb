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

FactoryBot.define do
  factory :unit do
    # name { Faker::Company.name }
    # ldap_group { Faker::Alphanumeric.alpha(number: 10) }
    name { "Fake Unit" }
    ldap_group { "fake_group" }
  end
end
