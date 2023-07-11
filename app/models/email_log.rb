# == Schema Information
#
# Table name: contacts
#
#  id               :bigint           not null, primary key
#  sent_from_model  :string
#  record_id        :string
#  email_type       :string
#  sent_to          :string
#  sent_by          :bigint
#  sent_at          :datetime
# 

class EmailLog < ApplicationRecord
end
