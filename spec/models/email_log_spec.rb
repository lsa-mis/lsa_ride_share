# == Schema Information
#
# Table name: email_logs
#
#  id              :bigint           not null, primary key
#  sent_from_model :string
#  record_id       :integer
#  email_type      :string
#  sent_to         :string
#  sent_by         :integer
#  sent_at         :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
require 'rails_helper'

RSpec.describe EmailLog, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
