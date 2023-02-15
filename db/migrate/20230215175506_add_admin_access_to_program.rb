class AddAdminAccessToProgram < ActiveRecord::Migration[7.0]
  def change
    add_reference :programs, :admin_accesses, index: true
  end
end
