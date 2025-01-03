class AddCanceledFieldToReservation < ActiveRecord::Migration[7.1]
  def change
    add_column :reservations, :canceled, :boolean, default: false
    add_column :reservations, :reason_for_cancellation, :string
  end
end
