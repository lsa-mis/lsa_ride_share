class ChangeSiteContactName < ActiveRecord::Migration[7.0]
  def change
    rename_table :site_contacts, :contacts
  end
end
