class CreateTerms < ActiveRecord::Migration[7.0]
  def change
    create_table :terms do |t|
      t.string :code
      t.string :name
      t.date :term_start
      t.date :term_end

      t.timestamps
    end
  end
end
