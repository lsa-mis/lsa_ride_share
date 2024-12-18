# == Schema Information
#
# Table name: managers_programs
#
#  id         :bigint           not null, primary key
#  manager_id :bigint
#  program_id :bigint
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'rails_helper'

RSpec.describe ManagersProgram, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
