# == Schema Information
#
# Table name: import_reservation_logs
#
#  id         :bigint           not null, primary key
#  date       :datetime
#  user       :string
#  unit_id    :integer
#  status     :string
#  note       :string           default([]), is an Array
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class ImportReservationLog < ApplicationRecord
end
