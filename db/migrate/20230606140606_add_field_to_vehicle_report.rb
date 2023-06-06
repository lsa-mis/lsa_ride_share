class AddFieldToVehicleReport < ActiveRecord::Migration[7.0]
  def change
    add_column :vehicle_reports, :student_status, :boolean, default: false
  end
end
