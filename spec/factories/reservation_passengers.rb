# == Schema Information
#
# Table name: reservation_passengers
#
#  id             :bigint           not null, primary key
#  reservation_id :bigint           not null
#  student_id     :bigint           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
FactoryBot.define do
  factory :reservation_passenger do
    reservation { nil }
    student { nil }
  end
end
