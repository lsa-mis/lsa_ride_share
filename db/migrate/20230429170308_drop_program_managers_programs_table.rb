class DropProgramManagersProgramsTable < ActiveRecord::Migration[7.0]
  def change
    drop_table :program_managers_programs
  end
end
