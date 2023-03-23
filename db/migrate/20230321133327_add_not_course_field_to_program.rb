class AddNotCourseFieldToProgram < ActiveRecord::Migration[7.0]
  def change
    add_column :programs, :not_course, :boolean, default: false
  end
end
