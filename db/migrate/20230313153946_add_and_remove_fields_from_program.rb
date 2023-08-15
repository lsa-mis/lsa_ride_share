class AddAndRemoveFieldsFromProgram < ActiveRecord::Migration[7.0]
  def change
    add_column :programs, :add_managers, :boolean, default: false
    remove_column :programs, :active
  end
end
