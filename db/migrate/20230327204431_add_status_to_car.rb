class AddStatusToCar < ActiveRecord::Migration[7.0]
  def change
    add_column :cars, :status, :integer
  end
end
