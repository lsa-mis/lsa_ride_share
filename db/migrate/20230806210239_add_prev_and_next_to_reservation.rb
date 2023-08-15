class AddPrevAndNextToReservation < ActiveRecord::Migration[7.0]
  def change
    add_column :reservations, :prev, :integer
    add_column :reservations, :next, :integer
  end
end
