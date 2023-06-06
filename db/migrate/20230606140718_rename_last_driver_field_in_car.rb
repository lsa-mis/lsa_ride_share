class RenameLastDriverFieldInCar < ActiveRecord::Migration[7.0]
  def change
    rename_column :cars, :last_driver, :last_driver_id
  end
end
