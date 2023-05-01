class DropAdminAccessTable < ActiveRecord::Migration[7.0]
  def change
    drop_table :admin_accesses
  end
end
