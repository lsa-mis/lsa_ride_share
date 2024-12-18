# == Schema Information
#
# Table name: managers
#
#  id                          :bigint           not null, primary key
#  uniqname                    :string
#  first_name                  :string
#  last_name                   :string
#  updated_by                  :integer
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  program_id                  :bigint
#  mvr_status                  :string
#  canvas_course_complete_date :date
#  meeting_with_admin_date     :date
#  phone_number                :string
#
require 'rails_helper'

RSpec.describe Manager, type: :model do

  context "the Factory" do
    it 'is valid' do
      expect(build(:manager)).to be_valid
    end
  end

end
