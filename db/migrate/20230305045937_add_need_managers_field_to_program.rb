class AddNeedManagersFieldToProgram < ActiveRecord::Migration[7.0]
  def change
    add_column :programs, :add_managers, :boolean, default: false
  end
end
