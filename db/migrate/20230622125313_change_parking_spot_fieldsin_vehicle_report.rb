class ChangeParkingSpotFieldsinVehicleReport < ActiveRecord::Migration[7.0]
  def change
    add_column :vehicle_reports, :parking_spot_return, :string
  end
end
