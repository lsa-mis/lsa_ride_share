class AddPhoneToManager < ActiveRecord::Migration[7.0]
  def change
    add_column :managers, :phone_number, :string
  end
end
