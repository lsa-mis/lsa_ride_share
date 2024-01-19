require 'rails_helper'

RSpec.describe Unit, type: :model do

  context "the Factory" do
    it 'is valid' do
      expect(build(:unit)).to be_valid
    end
  end

  context "create unit with all required fields present" do
    it 'is valid' do
      expect(create(:unit)).to be_valid
    end
  end

  context "create unit without a name" do
    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Name can\'t be blank"' do
      expect { FactoryBot.create(:unit, name: nil) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Name can't be blank")
    end
  end

  context "create unit without a ldap_group" do
    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Ldap group can\'t be blank"' do
      expect { FactoryBot.create(:unit, ldap_group: nil) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Ldap group can't be blank")
    end
  end

end
