class ChangeGasFieldTypeInCar < ActiveRecord::Migration[7.0]
  def change
    change_column :cars, :gas, :decimal
  end
end
