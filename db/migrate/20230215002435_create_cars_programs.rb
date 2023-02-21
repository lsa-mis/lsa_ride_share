class CreateCarsPrograms < ActiveRecord::Migration[7.0]
  def change
    create_table :cars_programs do |t|
      t.references :car, null: false, foreign_key: true
      t.references :program, null: false, foreign_key: true

      t.timestamps
    end
  end
end
