class AddProgramToStudents < ActiveRecord::Migration[7.0]
  def change
    add_reference :students, :program, foreign_key: true
  end
end
