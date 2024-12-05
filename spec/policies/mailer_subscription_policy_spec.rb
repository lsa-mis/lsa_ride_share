require 'rails_helper'

RSpec.describe MailerSubscriptionPolicy, type: :policy do
  let(:user) { FactoryBot.create(:user) }
  let(:mailer_subscription) { MailerSubscription.new }

  context 'with authenticated user to create mailer subscription' do
    subject { described_class.new({ user: user }, mailer_subscription) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_admin is_student is_manager user_in_access_group update edit]) }
    it { is_expected.to permit_only_actions(%i[index create new]) }
  end

  context 'with authenticated user to update mailer subscription' do
    let(:mailer_subscription) { FactoryBot.create(:mailer_subscription, user: user) }
    subject { described_class.new({ user: user }, mailer_subscription) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_admin is_student is_manager user_in_access_group]) }
    it { is_expected.to permit_only_actions(%i[index create new update edit]) }
  end

end
