# == Schema Information
#
# Table name: sites
#
#  id         :bigint           not null, primary key
#  title      :string
#  address1   :string
#  address2   :string
#  city       :string
#  state      :string
#  zip_code   :string
#  updated_by :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Site < ApplicationRecord
  has_and_belongs_to_many :programs
	has_rich_text :note
end
