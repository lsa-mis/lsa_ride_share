class AddNameToFacultySurvey < ActiveRecord::Migration[7.0]
  def change
    add_column :faculty_surveys, :first_name, :string
    add_column :faculty_surveys, :last_name, :string
  end
end
