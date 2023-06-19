class AddApprovedFieldToReservation < ActiveRecord::Migration[7.0]
  def change
    add_column :reservations, :approved, :boolean, default: false
  end
end
