class CreateCars < ActiveRecord::Migration[7.0]
  def change
    create_table :cars do |t|
      t.string :car_number
      t.string :make
      t.string :model
      t.string :color
      t.integer :number_of_seats
      t.float :mileage
      t.float :gas
      t.string :parking_spot
      t.datetime :last_used
      t.datetime :last_checked
      t.integer :last_driver
      t.integer :updated_by

      t.timestamps
    end
  end
end
