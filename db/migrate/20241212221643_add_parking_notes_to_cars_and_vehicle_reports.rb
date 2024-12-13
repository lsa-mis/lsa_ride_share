class AddParkingNotesToCarsAndVehicleReports < ActiveRecord::Migration[7.1]
  def change
    add_column :cars, :parking_note, :text
    add_column :vehicle_reports, :parking_note, :text
    add_column :vehicle_reports, :parking_note_return, :text
  end
end
