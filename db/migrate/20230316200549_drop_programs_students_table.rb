class DropProgramsStudentsTable < ActiveRecord::Migration[7.0]
  def change
    drop_table :programs_students
  end
end
