class RenameFieldsInTerm < ActiveRecord::Migration[7.0]
  def change
    rename_column :terms, :term_start, :classes_begin_date
    rename_column :terms, :term_end, :classes_end_date
  end
end
