class ChangeCarGasFieldsDatatype < ActiveRecord::Migration[7.0]
  def change
    change_column :cars, :gas, :integer
  end
end
