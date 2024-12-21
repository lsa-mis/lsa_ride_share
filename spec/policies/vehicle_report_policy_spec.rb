require 'rails_helper'

RSpec.describe VehicleReportPolicy, type: :policy do
  let!(:user) { FactoryBot.create(:user) }
  let!(:user_manager) { FactoryBot.create(:user) }
  let!(:manager) { FactoryBot.create(:manager, uniqname: user_manager.uniqname) }
  let!(:unit) { FactoryBot.create(:unit) }
  let!(:car) { FactoryBot.create(:car, unit: unit) }
  let!(:site) { FactoryBot.create(:site, unit: unit) }
  let!(:program) { FactoryBot.create(:program, unit: unit, instructor: manager) }

  context 'with super_admin role' do
    let!(:reservation) { FactoryBot.create(:reservation, program: program, site: site, car: car, reserved_by: user.id) }
    let!(:vehicle_report) { FactoryBot.create(:vehicle_report, reservation: reservation) }

    subject { described_class.new({ user: user, role: "super_admin", params: {id: vehicle_report.id, reservation_id: reservation.id} }, vehicle_report) }

    it { is_expected.to forbid_actions(%i[]) }
    it { is_expected.to permit_only_actions(%i[index show create new update edit upload_image delete_image destroy
    upload_damage_images upload_damage_form delete_damage_form download_vehicle_damage_form]) }
  end

  context 'with admin role' do
    let!(:reservation) { FactoryBot.create(:reservation, program: program, site: site, car: car, reserved_by: user.id) }
    let!(:vehicle_report) { FactoryBot.create(:vehicle_report, reservation: reservation) }

    subject { described_class.new({ user: user, role: "admin", params: {id: vehicle_report.id, reservation_id: reservation.id} }, vehicle_report) }

    it { is_expected.to forbid_actions(%i[]) }
    it { is_expected.to permit_only_actions(%i[index show create new update edit upload_image delete_image destroy
    upload_damage_images upload_damage_form delete_damage_form download_vehicle_damage_form]) }
  end

  context 'with manager role' do
    let!(:reservation_manager) { FactoryBot.create(:reservation, program: program, site: site, car: car, driver_manager_id: manager.id, reserved_by: user_manager.id) }
    let!(:vehicle_report_manager) { FactoryBot.create(:vehicle_report, reservation: reservation_manager) }

    subject { described_class.new({ user: user_manager, role: "manager", params: {id: vehicle_report_manager.id, reservation_id: reservation_manager.id} }, vehicle_report_manager) }

    it { is_expected.to forbid_actions(%i[index upload_damage_form delete_damage_form download_vehicle_damage_form]) }
    it { is_expected.to permit_only_actions(%i[show create new update edit upload_image delete_image destroy
    upload_damage_images]) }
  end

  context 'with student role' do
    let!(:user_student) { FactoryBot.create(:user) }
    let!(:student) { FactoryBot.create(:student, uniqname: user_student.uniqname, program: program) }
    let!(:reservation_student) { FactoryBot.create(:reservation, program: program, site: site, car: car, driver_id: student.id, reserved_by: user_student.id) }
    let!(:vehicle_report_student) { FactoryBot.create(:vehicle_report, reservation: reservation_student) }

    subject { described_class.new({ user: user_student, role: "student", params: {id: vehicle_report_student.id, reservation_id: reservation_student.id} }, vehicle_report_student) }
    it { is_expected.to forbid_actions(%i[index upload_damage_form delete_damage_form download_vehicle_damage_form]) }
    it { is_expected.to permit_only_actions(%i[show create new update edit upload_image delete_image destroy
    upload_damage_images]) }
  end

  context 'with no role' do
    let!(:user_none) { FactoryBot.create(:user) }
    let!(:reservation) { FactoryBot.create(:reservation, program: program, site: site, car: car, reserved_by: user.id) }
    let!(:vehicle_report) { FactoryBot.create(:vehicle_report, reservation: reservation) }

    subject { described_class.new({ user: user_none, role: "none", params: {id: vehicle_report.id, reservation_id: reservation.id}  }, reservation) }

    it { is_expected.to forbid_all_actions }
  end

end
