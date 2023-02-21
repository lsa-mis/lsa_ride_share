class CreateVehicleReports < ActiveRecord::Migration[7.0]
  def change
    create_table :vehicle_reports do |t|
      t.references :reservation, null: false, foreign_key: true
      t.float :mileage_start
      t.float :mileage_end
      t.float :gas_start
      t.float :gas_end
      t.string :parking_spot
      t.integer :created_by
      t.integer :updated_by
      t.string :status

      t.timestamps
    end
  end
end
