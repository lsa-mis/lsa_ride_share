class ChangeDefaultsInProgram < ActiveRecord::Migration[7.0]
  def change
    change_column_null :programs, :subject, null: false
    change_column_null :programs, :catalog_number, null: false
    change_column_null :programs, :class_section, null: false
  end
end
