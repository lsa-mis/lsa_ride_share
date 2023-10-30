class AddCourseToStudents < ActiveRecord::Migration[7.0]
  def change
    add_reference :students, :course, null: true, foreign_key: true
  end
end
