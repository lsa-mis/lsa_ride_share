class RenameProgramManagersTable < ActiveRecord::Migration[7.0]
  def change
    rename_table :program_managers, :managers
  end
end
