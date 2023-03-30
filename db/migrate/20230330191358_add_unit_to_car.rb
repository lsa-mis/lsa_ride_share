class AddUnitToCar < ActiveRecord::Migration[7.0]
  def change
    add_reference :cars, :unit, index: true
  end
end
