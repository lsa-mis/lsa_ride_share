class ChangeGasFieldsDatatype < ActiveRecord::Migration[7.0]
  def change
    change_column :vehicle_reports, :gas_start, :integer
    change_column :vehicle_reports, :gas_end, :integer
  end
end
