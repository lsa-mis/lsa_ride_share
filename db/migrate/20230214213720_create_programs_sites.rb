class CreateProgramsSites < ActiveRecord::Migration[7.0]
  def change
    create_table :programs_sites do |t|
      t.references :program, null: false, foreign_key: true
      t.references :site, null: false, foreign_key: true

      t.timestamps
    end
  end
end
