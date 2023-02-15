class CreateAdminAccesses < ActiveRecord::Migration[7.0]
  def change
    create_table :admin_accesses do |t|
      t.string :department
      t.string :ldap_group

      t.timestamps
    end
  end
end
