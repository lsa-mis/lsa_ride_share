class CreateSites < ActiveRecord::Migration[7.0]
  def change
    create_table :sites do |t|
      t.string :title
      t.string :address1
      t.string :address2
      t.string :city
      t.string :state
      t.string :zip_code
      t.integer :updated_by

      t.timestamps
    end
  end
end
