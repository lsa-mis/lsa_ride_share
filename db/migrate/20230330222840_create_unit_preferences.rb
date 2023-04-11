class CreateUnitPreferences < ActiveRecord::Migration[7.0]
  def change
    create_table :unit_preferences do |t|
      t.string :name
      t.string :description
      t.boolean :value
      t.references :unit, null: false, foreign_key: true

      t.timestamps
    end
  end
end
