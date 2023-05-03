class CreateFacultySurveys < ActiveRecord::Migration[7.0]
  def change
    create_table :faculty_surveys do |t|
      t.string :uniqname
      t.references :term, foreign_key: true
      t.references :unit, foreign_key: true

      t.timestamps
    end
  end
end
