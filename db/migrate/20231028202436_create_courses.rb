class CreateCourses < ActiveRecord::Migration[7.0]
  def change
    create_table :courses do |t|
      t.string :subject, null: false
      t.string :catalog_number, null: false
      t.string :class_section, null: false
      t.belongs_to :program, index: true

      t.timestamps
    end
  end
end
