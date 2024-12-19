require 'rails_helper'

RSpec.describe CarPolicy, type: :policy do
  let!(:user) { FactoryBot.create(:user) }
  let!(:car) { FactoryBot.create(:car)}

  context 'with super_admin role' do
    subject { described_class.new({ user: user, role: "super_admin" }, car) }

    it { is_expected.to forbid_actions(%i[]) }
    it { is_expected.to permit_only_actions(%i[index show create new update edit get_parking_locations delete_file]) }
  end

  context 'with admin role' do
    subject { described_class.new({ user: user, role: "admin" }, car) }

    it { is_expected.to forbid_actions(%i[]) }
    it { is_expected.to permit_only_actions(%i[index show create new update edit get_parking_locations delete_file]) }
  end

  context 'with manager role' do
    subject { described_class.new({ user: user, role: "manager" }, car) }

    it { is_expected.to forbid_actions(%i[index create new update edit get_parking_locations delete_file]) }
    it { is_expected.to permit_only_actions(%i[show]) }
  end

  context 'with student role' do
    subject { described_class.new({ user: user, role: "student" }, car) }

    it { is_expected.to forbid_actions(%i[index create new update edit get_parking_locations delete_file]) }
    it { is_expected.to permit_only_actions(%i[show]) }
  end

  context 'with no role' do
    subject { described_class.new({ user: user, role: "none" }, car) }

    it { is_expected.to forbid_all_actions }
  end

end
