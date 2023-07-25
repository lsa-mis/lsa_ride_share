class AddFieldsToManagers < ActiveRecord::Migration[7.0]
  def change
    add_column :managers, :mvr_status, :string
    add_column :managers, :canvas_course_complete_date, :date
    add_column :managers, :meeting_with_admin_date, :date
  end
end
