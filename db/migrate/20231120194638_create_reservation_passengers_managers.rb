class CreateReservationPassengersManagers < ActiveRecord::Migration[7.0]
  def change
    create_table :reservation_passengers_managers do |t|
      t.references :reservation, null: false, foreign_key: true
      t.references :manager, null: false, foreign_key: true

      t.timestamps
    end
  end
end
