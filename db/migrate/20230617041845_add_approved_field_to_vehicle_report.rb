class AddApprovedFieldToVehicleReport < ActiveRecord::Migration[7.0]
  def change
    add_column :vehicle_reports, :approved, :boolean, default: false
  end
end
