class AddCarIdToVehicleReports < ActiveRecord::Migration[7.1]
  def change
    add_reference :vehicle_reports, :car, null: true, foreign_key: true
    
    # Populate car_id for existing vehicle reports
    reversible do |dir|
      dir.up do
        VehicleReport.includes(:reservation).find_each do |vr|
          if vr.reservation&.car_id
            vr.update_column(:car_id, vr.reservation.car_id)
          end
        end
      end
    end
  end
end
