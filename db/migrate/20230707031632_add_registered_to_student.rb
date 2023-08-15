class AddRegisteredToStudent < ActiveRecord::Migration[7.0]
  def change
    add_column :students, :registered, :boolean, default: true
  end
end
