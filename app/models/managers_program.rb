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
class ManagersProgram < ApplicationRecord
  belongs_to :program
  belongs_to :manager

  validates :manager_id, uniqueness: { scope: :program_id, message: "is already a manager or instructor for this program" }

end
