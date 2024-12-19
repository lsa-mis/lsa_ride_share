require 'rails_helper'

RSpec.describe TermPolicy, type: :policy do
  let!(:user) { FactoryBot.create(:user) }
  let!(:term) { Term.new }

  context 'with super_admin role' do
    subject { described_class.new({ user: user, role: "super_admin" }, term) }

    it { is_expected.to forbid_actions(%i[]) }
    it { is_expected.to permit_only_actions(%i[index show create new update edit destroy]) }
  end

  context 'with admin role' do
    subject { described_class.new({ user: user, role: "admin" }, term) }

    it { is_expected.to forbid_actions(%i[]) }
    it { is_expected.to permit_only_actions(%i[index show create new update edit destroy]) }
  end

  context 'with manager role' do
    subject { described_class.new({ user: user, role: "manager" }, term) }

    it { is_expected.to forbid_actions(%i[index show create new update edit destroy]) }
    it { is_expected.to permit_only_actions(%i[]) }
  end

  context 'with student role' do
    subject { described_class.new({ user: user, role: "student" }, term) }

    it { is_expected.to forbid_actions(%i[index show create new update edit destroy]) }
    it { is_expected.to permit_only_actions(%i[]) }
  end

  context 'with no role' do
    subject { described_class.new({ user: user, role: "none" }, term) }

    it { is_expected.to forbid_all_actions }
  end

end
