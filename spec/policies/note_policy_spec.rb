require 'rails_helper'

RSpec.describe NotePolicy, type: :policy do
  let!(:user) { FactoryBot.create(:user) }
  let!(:note) { Note.new }

  context 'with super_admin role' do
    subject { described_class.new({ user: user, role: "super_admin" }, note) }

    it { is_expected.to forbid_actions(%i[]) }
    it { is_expected.to permit_only_actions(%i[index show create new update edit destroy]) }
  end

  context 'with admin role' do
    subject { described_class.new({ user: user, role: "admin" }, note) }

    it { is_expected.to forbid_actions(%i[]) }
    it { is_expected.to permit_only_actions(%i[index show create new update edit destroy]) }
  end

  context 'with manager role' do
    let!(:user_manager) { FactoryBot.create(:manager, uniqname: user.uniqname) }
    subject { described_class.new({ user: user_manager, role: "manager" }, note) }

    it { is_expected.to forbid_actions(%i[index show create new update edit destroy]) }
    it { is_expected.to permit_only_actions(%i[]) }
  end

  context 'with student role' do
    let!(:user_student) { FactoryBot.create(:student, uniqname: user.uniqname) }
    subject { described_class.new({ user: user_student, role: "student" }, note) }

    it { is_expected.to forbid_actions(%i[index show create new update edit destroy]) }
    it { is_expected.to permit_only_actions(%i[]) }
  end

  context 'with no role' do
    subject { described_class.new({ user: user, role: "none" }, note) }

    it { is_expected.to forbid_all_actions }
  end

end
