class AddColumnsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :uid, :string
    add_column :users, :uniqname, :string
    add_column :users, :principal_name, :string
    add_column :users, :display_name, :string
    add_column :users, :person_affiliation, :string
  end
end
