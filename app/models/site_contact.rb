# == Schema Information
#
# Table name: sites
#
#  id           :bigint           not null, primary key
#  title        :string
#  first_name   :string
#  last_name    :string
#  phone_number :string
#  site_id      :bigint

class SiteContact < ApplicationRecord
  belongs_to: site

  def display_name
    "#{self.title}: #{self.first_name} #{self.last_name}, #{self.email}, #{self.phone_number}"
  end
end
