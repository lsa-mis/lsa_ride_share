class RemoveAdminAccessFromProgram < ActiveRecord::Migration[7.0]
  def change
    remove_reference :programs, :admin_access, index: true
  end
end
