class AddPreferredNameToStudents < ActiveRecord::Migration[8.1]
  def change
    add_column :students, :preferred_name, :string
  end
end
