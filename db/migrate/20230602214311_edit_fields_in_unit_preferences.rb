class EditFieldsInUnitPreferences < ActiveRecord::Migration[7.0]
  def change
    rename_column :unit_preferences, :value, :on_off
    add_column :unit_preferences, :value, :string
    add_column :unit_preferences, :pref_type, :integer
  end
end
