class CreateReservationPassengers < ActiveRecord::Migration[7.0]
  def change
    create_table :reservation_passengers do |t|
      t.references :reservation, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: true

      t.timestamps
    end
  end
end
