class CreateEmailLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :email_logs do |t|
      t.string :sent_from_model
      t.integer :record_id
      t.string :email_type
      t.string :sent_to
      t.integer :sent_by
      t.datetime :sent_at

      t.timestamps
    end
  end
end
