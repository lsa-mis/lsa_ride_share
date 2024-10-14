require 'rails_helper'

RSpec.describe Manager, type: :model do

  context "the Factory" do
    it 'is valid' do
      expect(build(:manager)).to be_valid
    end
  end

end
