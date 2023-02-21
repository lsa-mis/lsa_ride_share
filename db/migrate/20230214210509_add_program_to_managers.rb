class AddProgramToManagers < ActiveRecord::Migration[7.0]
  def change
    add_reference :program_managers, :program, index: true
  end
end
