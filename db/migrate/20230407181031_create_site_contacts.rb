class CreateSiteContacts < ActiveRecord::Migration[7.0]
  def change
    create_table :site_contacts do |t|
      t.string :title
      t.string :first_name
      t.string :last_name
      t.string :phone_number
      t.string :email
      t.references :site, null: false, foreign_key: true

      t.timestamps
    end
  end
end
