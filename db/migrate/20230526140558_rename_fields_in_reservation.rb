class RenameFieldsInReservation < ActiveRecord::Migration[7.0]
  def change
    rename_column :reservations, :start_date, :start_time
    rename_column :reservations, :end_date, :end_time
  end
end
