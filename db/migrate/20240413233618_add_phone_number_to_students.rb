class AddPhoneNumberToStudents < ActiveRecord::Migration[7.0]
  def change
    add_column :students, :phone_number, :string
  end
end
