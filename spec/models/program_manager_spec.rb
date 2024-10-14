# == Schema Information
#
# Table name: program_managers
#
#  id         :bigint           not null, primary key
#  uniqname   :string
#  first_name :string
#  last_name  :string
#  updated_by :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  program_id :bigint
#
require 'rails_helper'

# RSpec.describe ProgramManager, type: :model do
#   pending "add some examples to (or delete) #{__FILE__}"
# end
