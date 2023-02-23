class ChangeFiedInProgram < ActiveRecord::Migration[7.0]
  def change
    remove_column :programs, :term
    add_column :programs, :term_id, :integer
  end
end
