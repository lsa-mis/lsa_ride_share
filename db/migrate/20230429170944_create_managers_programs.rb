class CreateManagersPrograms < ActiveRecord::Migration[7.0]
  def change
    create_table :managers_programs do |t|
      t.belongs_to :manager
      t.belongs_to :program

      t.timestamps
    end
  end
end
