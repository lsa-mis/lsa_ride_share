# == Schema Information
#
# Table name: students
#
#  id                          :bigint           not null, primary key
#  uniqname                    :string
#  last_name                   :string
#  first_name                  :string
#  canvas_course_complete_date :date
#  updated_by                  :integer
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  mvr_status                  :string
#  program_id                  :bigint
#  meeting_with_admin_date     :date
#  registered                  :boolean          default(TRUE)
#  course_id                   :bigint
#  phone_number                :string
#
require 'rails_helper'

RSpec.describe Student, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
