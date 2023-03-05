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
class ProgramManager < ApplicationRecord
  has_and_belongs_to_many :programs

  validates :uniqname, uniqueness: true

  def instructor
    Program.where(instructor: self)
  end

  def manager
    Program.includes(:program_managers).where(program_managers_programs: [self])
  end

  def programs
    manager + instructor
  end

  def display_name
    "#{self.first_name} #{self.last_name} - #{self.uniqname}" 
  end
end
