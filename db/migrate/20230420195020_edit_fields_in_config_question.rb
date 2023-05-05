class EditFieldsInConfigQuestion < ActiveRecord::Migration[7.0]
  def change
    remove_column :config_questions, :program_id
    add_reference :config_questions, :faculty_survey, index: true
  end
end
