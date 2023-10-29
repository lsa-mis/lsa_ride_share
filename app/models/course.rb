# == Schema Information
#
# Table name: courses
#
#  subject                             :string           not null
#  catalog_number                      :string           not null
#  class_section                       :string           not null
#  program_id                          :integer
# 
class Course < ApplicationRecord
  belongs_to :program

  def display_name
    "#{self.subject} #{self.catalog_number} - #{self.class_section}"
  end

end
