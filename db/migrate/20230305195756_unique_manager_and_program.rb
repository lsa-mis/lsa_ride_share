class UniqueManagerAndProgram < ActiveRecord::Migration[7.0]
  def change
    change_table :program_managers_programs do |t|
      t.index %i[program_manager_id program_id], unique: true, name: 'manager_program_index'
    end
  end
end
