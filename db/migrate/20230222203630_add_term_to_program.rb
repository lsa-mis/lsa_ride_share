class AddTermToProgram < ActiveRecord::Migration[7.0]
  def change
    add_column :programs, :term, :string
  end
end
