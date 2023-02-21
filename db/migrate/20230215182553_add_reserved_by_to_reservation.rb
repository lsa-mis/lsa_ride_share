class AddReservedByToReservation < ActiveRecord::Migration[7.0]
  def change
    add_column :reservations, :reserved_by, :integer
  end
end
