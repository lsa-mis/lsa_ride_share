class CreateConfigQuestions < ActiveRecord::Migration[7.0]
  def change
    create_table :config_questions do |t|
      t.references :program, null: false, foreign_key: true

      t.timestamps
    end
  end
end
