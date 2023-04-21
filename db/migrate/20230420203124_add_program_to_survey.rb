class AddProgramToSurvey < ActiveRecord::Migration[7.0]
  def change
    add_column :faculty_surveys, :program_id, :integer
  end
end
