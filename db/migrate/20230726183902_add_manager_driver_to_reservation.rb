class AddManagerDriverToReservation < ActiveRecord::Migration[7.0]
  def change
    add_reference :reservations, :driver_manager, foreign_key: {to_table: :managers}, optional: true, index: true
  end
end
