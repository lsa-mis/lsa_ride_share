class AddFieldsToProgram < ActiveRecord::Migration[7.0]
  def change
    add_column :programs, :mvr_link, :string
    add_column :programs, :canvas_link, :string
    add_column :programs, :canvas_course_id, :integer
  end
end
