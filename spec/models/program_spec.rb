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
      expect(program).to be_valid
    end
  end

  context "create program with all required fields present" do
    it 'is valid' do
      program = build(:program)
      expect(program).to be_valid
    end
  end

  context "check validation for title uniqness for a term" do
    it 'raise error "ActiveRecord::RecordInvalid: Term already has this program"' do
      unit = create(:unit)
      term = create(:term)
      program = create(:program, term: term, unit: unit)
      expect{ FactoryBot.create(:program, term: term, unit: unit, title: program.title) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Term already has this program")
    end
  end

end
