# == Schema Information
#
# Table name: programs
#
#  id                                  :bigint           not null, primary key
#  title                               :string
#  subject                             :string           not null
#  catalog_number                      :string           not null
#  class_section                       :string           not null
#  number_of_students                  :integer
#  number_of_students_using_ride_share :integer
#  pictures_required_start             :boolean          default(FALSE)
#  pictures_required_end               :boolean          default(FALSE)
#  non_uofm_passengers                 :boolean          default(FALSE)
#  instructor_id                       :bigint           not null
#  updated_by                          :integer
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  mvr_link                            :string
#  canvas_link                         :string
#  canvas_course_id                    :integer
#  term_id                             :integer
#  add_managers                        :boolean          default(FALSE)
#  not_course                          :boolean          default(FALSE)
#
require 'rails_helper'

RSpec.describe Program, type: :model do
  context "the Factory" do
    it 'is valid' do
      program = build(:program)
      # binding.pry
      expect(program).to be_valid
    end
  end

  context "create program with all required fields present" do
    it 'is valid' do
      program = build(:program)
      instructor = FactoryBot.build(:manager)
      instructor.save
      unit = FactoryBot.create(:unit)
      program = FactoryBot.build(:program, instructor: instructor, unit: unit)
      expect(program).to be_valid
    end
  end
end
