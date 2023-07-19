class AddNonUofMPassengersToReservation < ActiveRecord::Migration[7.0]
  def change
    add_column :reservations, :non_uofm_passengers, :string
    add_column :reservations, :number_of_non_uofm_passengers, :integer, default: 0
  end
end
