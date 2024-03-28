class CreateMailerSubscriptions < ActiveRecord::Migration[7.0]
  def change
    create_table :mailer_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.boolean :subscribed
      t.string :mailer, null: false

      t.timestamps
    end

    add_index(:mailer_subscriptions, [:user_id, :mailer], unique: true)
  end
end
