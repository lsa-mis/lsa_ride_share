class RemoveFiedsInProgram < ActiveRecord::Migration[7.0]
  def change
    remove_column :programs, :term_code
    remove_column :programs, :term_start
    remove_column :programs, :term_end
  end
end
