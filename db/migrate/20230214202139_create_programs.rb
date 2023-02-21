class CreatePrograms < ActiveRecord::Migration[7.0]
  def change
    create_table :programs do |t|
      t.boolean :active, default: true
      t.string :title
      t.date :term_start, null: false
      t.date :term_end, null: false
      t.string :term_code, null: false
      t.string :subject, null: false
      t.string :catalog_number, null: false
      t.string :class_section, null: false
      t.integer :number_of_students
      t.integer :number_of_students_using_ride_share
      t.boolean :pictures_required_start, default: false
      t.boolean :pictures_required_end, default: false
      t.boolean :non_uofm_passengers, default: false
      t.references :instructor, foreign_key: {to_table: :program_managers}, null: false
      t.integer :updated_by

      t.timestamps
    end
  end
end
