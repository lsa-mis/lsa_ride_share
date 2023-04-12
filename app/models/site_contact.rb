# == Schema Information
#
# Table name: site_contacts
#
#  id           :bigint           not null, primary key
#  title        :string
#  first_name   :string
#  last_name    :string
#  phone_number :string
#  email       :string
#  site_id      :bigint

class SiteContact < ApplicationRecord
  belongs_to :site

  validates_presence_of :title, :first_name, :last_name
  validates :phone_number, presence: true, format: { with: /\A(?:\+?\d{1,3}\s*-?)?\(?(?:\d{3})?\)?[- ]?\d{3}[- ]?\d{4}\z/, message: "format is incorrect"}
  validates :email, presence: true, length: {maximum: 255}, format: {with: URI::MailTo::EMAIL_REGEXP, message: "format is incorrect"}

  def display_name
    "#{self.title}: #{self.first_name} #{self.last_name}, #{self.email}, #{self.phone_number}"
  end
end
