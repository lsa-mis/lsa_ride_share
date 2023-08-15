class AddUntilDateToReservation < ActiveRecord::Migration[7.0]
  def change
    add_column :reservations, :until_date, :date
  end
end
