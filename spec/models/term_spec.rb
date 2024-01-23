# == Schema Information
#
# Table name: terms
#
#  id                 :bigint           not null, primary key
#  code               :string
#  name               :string
#  classes_begin_date :date
#  classes_end_date   :date
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
require 'rails_helper'

RSpec.describe Term, type: :model do

  context "the Factory" do
    it 'is valid' do
      expect(build(:term)).to be_valid
    end
  end

  context "create term with all required fields present" do
    it 'is valid' do
      expect(create(:term)).to be_valid
    end
  end

  context "create term without a code" do
    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Code can\'t be blank"' do
      expect { FactoryBot.create(:term, code: nil) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Code can't be blank")
    end
  end

  context "create term without a name" do
    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Name can\'t be blank"' do
      expect { FactoryBot.create(:term, name: nil) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Name can't be blank")
    end
  end

  context "create term without a classes_begin_date" do
    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Classes begin date can\'t be blank"' do
      expect { FactoryBot.create(:term, classes_begin_date: nil) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Classes begin date can't be blank")
    end
  end

  context "create term without a classes_end_date" do
    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Classes end date can\'t be blank"' do
      expect { FactoryBot.create(:term, classes_end_date: nil) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Classes end date can't be blank")
    end
  end

end
