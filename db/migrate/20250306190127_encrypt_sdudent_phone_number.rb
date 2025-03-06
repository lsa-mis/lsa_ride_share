class EncryptSdudentPhoneNumber < ActiveRecord::Migration[7.1]
  def up
    students =  Student.all
    students.each do |student|
      student.encrypt
    end
  end
  def down
   # Needed in the config you're using (production.rb, development.rb)
   # config.active_record.encryption.support_unencrypted_data = true
   students =  Student.all
   students.each do |student|
      student.decrypt
    end
  end
end
