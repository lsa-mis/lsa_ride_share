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
FactoryBot.define do
  factory :site do
    title { Faker::Address.community }
    address1 { Faker::Address.street_address }
    address2 { Faker::Address.secondary_address }
    city { Faker::Address.city }
    state { Faker::Address.state }
    zip_code { Faker::Address.zip }
    association :unit

    factory :site_with_contact do
      after(:create) do |site|
        create(:contact, site: site)
      end
    end
  end
end
