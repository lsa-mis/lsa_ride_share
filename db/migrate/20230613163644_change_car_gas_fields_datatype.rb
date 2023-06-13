class ChangeCarGasFieldsDatatype < ActiveRecord::Migration[7.0]
  def change
    change_column :car, :gas, :integer
  end
end
