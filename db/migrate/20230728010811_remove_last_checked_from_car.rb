class RemoveLastCheckedFromCar < ActiveRecord::Migration[7.0]
  def change
    remove_column :cars, :last_checked
  end
end
