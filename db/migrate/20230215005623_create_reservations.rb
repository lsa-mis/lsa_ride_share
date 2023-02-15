class CreateReservations < ActiveRecord::Migration[7.0]
  def change
    create_table :reservations do |t|
      t.string :status
      t.references :program, null: false, foreign_key: true
      t.references :site, null: false, foreign_key: true
      t.references :car, foreign_key: true, optional: true
      t.datetime :start_date
      t.datetime :end_date
      t.string :recurring
      t.references :driver, foreign_key: {to_table: :students}, optional: true
      t.string :driver_phone
      t.references :backup_driver, foreign_key: {to_table: :students}, optional: true
      t.string :backup_driver_phone
      t.integer :number_of_people_on_trip
      t.integer :updated_by

      t.timestamps
    end
  end
end
