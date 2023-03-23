class ChangeFieldsInStudents < ActiveRecord::Migration[7.0]
  def change
    remove_column :students, :mvr_expiration_date
    add_column :students, :mvr_status, :string
  end
end
