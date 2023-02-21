class CreateProgramsStudents < ActiveRecord::Migration[7.0]
  def change
    create_table :programs_students do |t|
      t.references :program, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: true

      t.timestamps
    end
  end
end
