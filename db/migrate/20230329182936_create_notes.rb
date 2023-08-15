class CreateNotes < ActiveRecord::Migration[7.0]
  def change
    create_table :notes do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.belongs_to :noteable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
