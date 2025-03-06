class EncryptManagerPhoneNumber < ActiveRecord::Migration[7.1]
  def up
    managers =  Manager.all
    managers.each do |manager|
      manager.encrypt
    end
  end
  def down
   # Needed in the config you're using (production.rb, development.rb)
   # config.active_record.encryption.support_unencrypted_data = true
   managers =  Manager.all
   managers.each do |manager|
      manager.decrypt
    end
  end
end
