class AddParkingNotesToCarsAndVehicleReports < ActiveRecord::Migration[7.1]
  def change
    add_column :cars, :parking_notes, :text
    add_column :vehicle_reports, :parking_notes, :text
  end
end
