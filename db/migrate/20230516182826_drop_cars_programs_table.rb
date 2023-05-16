class DropCarsProgramsTable < ActiveRecord::Migration[7.0]
  def change
    drop_table :cars_programs
  end
end
