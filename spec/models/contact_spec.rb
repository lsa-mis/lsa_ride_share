# == Schema Information
#
# Table name: contacts
#
#  id           :bigint           not null, primary key
#  title        :string
#  first_name   :string
#  last_name    :string
#  phone_number :string
#  email        :string
#  site_id      :bigint           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
require 'rails_helper'

RSpec.describe Contact, type: :model do

  context "the Factory" do
    it 'is valid' do
      contact = build(:contact)
      puts contact.phone_number
      expect(contact).to be_valid
    end
  end

  context "create contact with all required fields present" do
    it 'is valid' do
      expect(create(:contact)).to be_valid
    end
  end

  context "create contact without a title" do
    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Title number can\'t be blank"' do
      expect { create(:contact, title: nil) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Title can't be blank")
    end
  end

  context "create contact without a first_name" do
    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: First name number can\'t be blank"' do
      expect { create(:contact, first_name: nil) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: First name can't be blank")
    end
  end

  context "create contact without a last_name" do
    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Last name number can\'t be blank"' do
      expect { create(:contact, last_name: nil) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Last name can't be blank")
    end
  end

  context "create contact without a phone_number" do
    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Phone number number can\'t be blank, Phone number format is incorrect"' do
      expect { create(:contact, phone_number: nil) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Phone number can't be blank, Phone number format is incorrect")
    end
  end

  context "create contact without a email" do
    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Email can\'t be blank, Email format is incorrect"' do
      expect { create(:contact, email: nil) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Email can't be blank, Email format is incorrect")
    end
  end

  context "create contact without a site" do
    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Unit must exist"' do
      expect { FactoryBot.create(:contact, site: nil) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Site must exist")
    end
  end

end
