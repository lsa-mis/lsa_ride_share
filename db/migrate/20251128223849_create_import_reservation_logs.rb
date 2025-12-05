class CreateImportReservationLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :import_reservation_logs do |t|
      t.datetime :date
      t.string :user
      t.integer :unit_id
      t.string :status
      t.string :note, array: true, default: []

      t.timestamps
    end
  end
end
