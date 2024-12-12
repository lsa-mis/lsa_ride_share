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
require 'rails_helper'

RSpec.describe Site, type: :model do

  context "the Factory" do
    it 'is valid' do
      expect(build(:site)).to be_valid
    end
  end

  context "create site with all required fields present" do
    it 'is valid' do
      expect(create(:site, address2: nil)).to be_valid
    end
  end

  context "create site without a title" do
    let!(:user) { FactoryBot.create(:user) }

    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Title can\'t be blank"' do
      expect { FactoryBot.create(:site, title: nil, updated_by: user.id) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Title can't be blank")
    end
  end

  context "create site without a address1" do
    let!(:user) { FactoryBot.create(:user) }

    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Address1 can\'t be blank"' do
      expect { FactoryBot.create(:site, address1: nil, updated_by: user.id) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Address1 can't be blank")
    end
  end

  context "create site without a city" do
    let!(:user) { FactoryBot.create(:user) }

    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: City can\'t be blank"' do
      expect { FactoryBot.create(:site, city: nil, updated_by: user.id) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: City can't be blank")
    end
  end

  context "create site without a state" do
    let!(:user) { FactoryBot.create(:user) }

    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: State can\'t be blank"' do
      expect { FactoryBot.create(:site, state: nil, updated_by: user.id) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: State can't be blank")
    end
  end

  context "create site without a zip_code" do
    let!(:user) { FactoryBot.create(:user) }

    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Zip code can\'t be blank, Zip code should be in the form 12345 or 12345-1234"' do
      expect { FactoryBot.create(:site, zip_code: nil, updated_by: user.id) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Zip code can't be blank, Zip code should be in the form 12345 or 12345-1234")
    end
  end

  context "validate a zip_code" do
    let!(:user) { FactoryBot.create(:user) }

    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: , Zip code should be in the form 12345 or 12345-1234"' do
      expect { FactoryBot.create(:site, zip_code: "hgfd-jjjhhg", updated_by: user.id) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Zip code should be in the form 12345 or 12345-1234")
    end
  end

  # the folowimng validation is not working
  # context "validate a zip_code" do
  #   let!(:user) { FactoryBot.create(:user) }

  #   it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Zip code can\'t be blank"' do
  #     expect { FactoryBot.create(:site, zip_code: "123456567", updated_by: user.id) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Zip code should be in the form 12345 or 12345-1234")
  #   end
  # end

  # updated_by is not required - should it be?
  # context "create site without a updated_by" do

  #   it 'raise error "ActiveRecord::RecordInvalid: Validation failed: updated_by can\'t be blank"' do
  #     expect { FactoryBot.create(:site, updated_by: nil) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Updated by can't be blank")
  #   end
  # end

  context "validate a unit presence" do
    let!(:user) { FactoryBot.create(:user) }

    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Unit must exist' do
      expect { FactoryBot.create(:site, unit_id: nil, updated_by: user.id) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Unit must exist")
    end
  end

  context "validate a title uniqueness" do
    let!(:user) { FactoryBot.create(:user) }
    let!(:site1) { FactoryBot.create(:site, title: "New Title") }

    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Site already exist' do
      expect { FactoryBot.create(:site, title: site1.title, unit: site1.unit, updated_by: user.id) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Title already exist")
    end
  end

  # how to test accepts_nested_attributes_for ?
  # context "accepts_nested_attributes_for :contacts" do
  #   let!(:user) { FactoryBot.create(:user) }

  #   it{ should accept_nested_attributes_for(:contacts) }
  # end

end
