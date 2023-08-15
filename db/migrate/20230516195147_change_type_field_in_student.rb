class ChangeTypeFieldInStudent < ActiveRecord::Migration[7.0]
  def change
    remove_column :students, :meeting_with_admin_date
    add_column :students, :meeting_with_admin_date, :date
  end
end
