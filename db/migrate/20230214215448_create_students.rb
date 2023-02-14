class CreateStudents < ActiveRecord::Migration[7.0]
  def change
    create_table :students do |t|
      t.string :uniqname
      t.string :last_name
      t.string :first_name
      t.date :mvr_expiration_date
      t.date :class_training_date
      t.date :canvas_course_complete_date
      t.string :meeting_with_admin_date
      t.integer :updated_by

      t.timestamps
    end
  end
end
