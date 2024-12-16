# == Schema Information
#
# Table name: mailer_subscriptions
#
#  id           :bigint           not null, primary key
#  user_id      :bigint           not null
#  unsubscribed :boolean
#  mailer       :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
require 'rails_helper'

RSpec.describe MailerSubscription, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
