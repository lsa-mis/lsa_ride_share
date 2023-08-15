class AddTitleToFacultySurvey < ActiveRecord::Migration[7.0]
  def change
    add_column :faculty_surveys, :title, :string
  end
end
