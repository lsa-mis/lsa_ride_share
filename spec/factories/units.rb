FactoryBot.define do
  factory :unit do
    name { Faker::Company.name }
    ldap_group { Faker::String.random(length: 6..12) }
  end
end
