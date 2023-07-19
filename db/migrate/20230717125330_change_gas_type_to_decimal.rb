class ChangeGasTypeToDecimal < ActiveRecord::Migration[7.0]
  def change
    change_column :vehicle_reports, :gas_start, :decimal
    change_column :vehicle_reports, :gas_end, :decimal
  end
end
