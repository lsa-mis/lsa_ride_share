class AddAdminAccessToProgram < ActiveRecord::Migration[7.0]
  def change
    add_reference :programs, :admin_access, index: true
  end
end
