# == Schema Information
#
# Table name: cars
#
#  id              :bigint           not null, primary key
#  car_number      :string
#  make            :string
#  model           :string
#  color           :string
#  number_of_seats :integer
#  mileage         :float
#  gas             :decimal(, )
#  parking_spot    :string
#  last_used       :datetime
#  last_driver_id  :integer
#  updated_by      :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  status          :integer
#  unit_id         :bigint
#  parking_note    :text
#


require 'rails_helper'

RSpec.describe Car, type: :model do

  context "the Factory" do
    it 'is valid' do
      expect(build(:car)).to be_valid
    end
  end

  context "create car with all required fields present" do
    let!(:user) { FactoryBot.create(:user) }

    it 'is valid' do
      expect(create(:car, updated_by: user.id)).to be_valid
    end
  end

  context "create car without a car_number" do
    let!(:user) { FactoryBot.create(:user) }

    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Car number can\'t be blank"' do
      expect { FactoryBot.create(:car, car_number: nil, updated_by: user.id) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Car number can't be blank")
    end
  end

  context "create car without a make" do
    let!(:user) { FactoryBot.create(:user) }

    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Make can\'t be blank"' do
      expect { FactoryBot.create(:car, make: nil, updated_by: user.id) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Make can't be blank")
    end
  end

  context "create car without a model" do
    let!(:user) { FactoryBot.create(:user) }

    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Model can\'t be blank"' do
      expect { FactoryBot.create(:car, model: nil, updated_by: user.id) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Model can't be blank")
    end
  end

  context "create car without a color" do
    let!(:user) { FactoryBot.create(:user) }

    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Color can\'t be blank"' do
      expect { FactoryBot.create(:car, color: nil, updated_by: user.id) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Color can't be blank")
    end
  end

  context "create car without a number_of_seats" do
    let!(:user) { FactoryBot.create(:user) }

    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Number of seats can\'t be blank"' do
      expect { FactoryBot.create(:car, number_of_seats: nil, updated_by: user.id) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Number of seats can't be blank")
    end
  end

  context "create car without a mileage" do
    let!(:user) { FactoryBot.create(:user) }

    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Mileage can\'t be blank, Mileage must be positive"' do
      expect { FactoryBot.create(:car, mileage: nil, updated_by: user.id) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Mileage can't be blank, Mileage must be positive")
    end
  end

  context "create car wit a negative mileage" do
    let!(:user) { FactoryBot.create(:user) }

    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Mileage must be positive"' do
      expect { FactoryBot.create(:car, mileage: -10, updated_by: user.id) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Mileage must be positive")
    end
  end

  context "create car wit a zero mileage" do
    let!(:user) { FactoryBot.create(:user) }

    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Mileage must be positive"' do
      expect { FactoryBot.create(:car, mileage: 0, updated_by: user.id) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Mileage must be positive")
    end
  end

  context "create car without a gas" do
    let!(:user) { FactoryBot.create(:user) }

    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Gas can\'t be blank"' do
      expect { FactoryBot.create(:car, gas: nil, updated_by: user.id) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Gas can't be blank")
    end
  end

  context "create car without a parking_spot" do
    let!(:user) { FactoryBot.create(:user) }

    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Parking spot can\'t be blank"' do
      expect { FactoryBot.create(:car, parking_spot: nil, updated_by: user.id) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Parking spot can't be blank")
    end
  end

  context "create car without a status" do
    let!(:user) { FactoryBot.create(:user) }

    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Status can\'t be blank"' do
      expect { FactoryBot.create(:car, status: nil, updated_by: user.id) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Status can't be blank")
    end
  end

  context "create car without a updated_by" do
    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Updated by can\'t be blank"' do
      expect { FactoryBot.create(:car, updated_by: nil) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Updated by can't be blank")
    end
  end

  context "create car without a unit" do
    let!(:user) { FactoryBot.create(:user) }

    it 'raise error "ActiveRecord::RecordInvalid: Validation failed: Unit must exist"' do
      expect { FactoryBot.create(:car, unit: nil, updated_by: user.id) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Unit must exist")
    end
  end

end
