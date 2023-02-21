class CreateProgramManagers < ActiveRecord::Migration[7.0]
  def change
    create_table :program_managers do |t|
      t.string :uniqname
      t.string :first_name
      t.string :last_name
      t.integer :updated_by

      t.timestamps
    end
  end
end
