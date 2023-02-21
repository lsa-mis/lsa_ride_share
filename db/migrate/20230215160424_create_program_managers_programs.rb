class CreateProgramManagersPrograms < ActiveRecord::Migration[7.0]
  def change
    create_table :program_managers_programs do |t|
      t.references :program_manager, null: false, foreign_key: true
      t.references :program, null: false, foreign_key: true

      t.timestamps
    end
  end
end
