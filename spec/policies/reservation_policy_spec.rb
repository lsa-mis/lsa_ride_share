require 'rails_helper'

RSpec.describe ReservationPolicy, type: :policy do
  let(:user) { FactoryBot.create(:user) }
  let(:user_manager) { FactoryBot.create(:user) }
  let(:manager) { FactoryBot.create(:manager, uniqname: user_manager.uniqname) }
  let(:unit) { FactoryBot.create(:unit) }
  let(:car) { FactoryBot.create(:car, unit: unit) }
  let(:site) { FactoryBot.create(:site, unit: unit) }
  let(:program) { FactoryBot.create(:program, unit: unit, instructor: manager) }
  let(:user_student) { FactoryBot.create(:user) }
  let(:student) { FactoryBot.create(:student, uniqname: user_student.uniqname, program: program) }
  let(:reservation_admin) { FactoryBot.create(:reservation, program: program, site: site, car: car, reserved_by: user.id) }
  let(:reservation_manager) { FactoryBot.create(:reservation, program: program, site: site, car: car, reserved_by: user_manager.id) }
  let(:reservation_student) { FactoryBot.create(:reservation, program: program, site: site, car: car, driver_id: student.id, reserved_by: user_student.id) }
  let(:user_none) { FactoryBot.create(:user) }

  context 'with super_admin role' do
    subject { described_class.new({ user: user, role: "super_admin", params: {unit_id: program.unit.id} }, reservation_admin) }

    it { is_expected.to forbid_actions(%i[is_admin is_student is_manager is_in_reservation is_reservation_driver]) }
    it { is_expected.to permit_only_actions(%i[is_super_admin user_in_access_group index week_calendar day_reservations show create new new_long update edit edit_long 
      get_available_cars get_available_cars_long no_car_all_times edit_change_day change_start_end_day add_drivers_later finish_reservation 
      send_reservation_updated_email add_non_uofm_passengers update_passengers destroy cancel_recurring_reservation approve_all_recurring
      selected_reservations send_email_to_selected_reservations is_reserved_by]) }
  end

  context 'with admin role and reservation created by admin' do
    subject { described_class.new({ user: user, role: "admin", params: {unit_id: program.unit.id} }, reservation_admin) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_student is_manager is_in_reservation is_reservation_driver]) }
    it { is_expected.to permit_only_actions(%i[is_admin user_in_access_group index week_calendar day_reservations show create new new_long update edit edit_long 
      get_available_cars get_available_cars_long no_car_all_times edit_change_day change_start_end_day add_drivers_later finish_reservation 
      send_reservation_updated_email add_non_uofm_passengers update_passengers destroy cancel_recurring_reservation approve_all_recurring
      selected_reservations send_email_to_selected_reservations is_reserved_by]) }
  end

  context 'with admin role and reservation created by student' do
    subject { described_class.new({ user: user, role: "admin", params: {unit_id: program.unit.id} }, reservation_student) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_student is_manager is_in_reservation is_reservation_driver]) }
    it { is_expected.to permit_only_actions(%i[is_admin user_in_access_group index week_calendar day_reservations show create new new_long update edit edit_long 
      get_available_cars get_available_cars_long no_car_all_times edit_change_day change_start_end_day add_drivers_later finish_reservation 
      send_reservation_updated_email add_non_uofm_passengers update_passengers destroy cancel_recurring_reservation approve_all_recurring
      selected_reservations send_email_to_selected_reservations]) }
  end

  context 'with manager role' do
    subject { described_class.new({ user: user_manager, role: "manager", params: {unit_id: program.unit.id} }, reservation_manager) }

    it { is_expected.to forbid_actions(%i[is_super_admin is_admin is_student user_in_access_group add_drivers_later index week_calendar
      day_reservations approve_all_recurring selected_reservations send_email_to_selected_reservations send_reservation_updated_email]) }
    it { is_expected.to permit_only_actions(%i[is_manager show create new new_long update edit edit_long 
      get_available_cars get_available_cars_long no_car_all_times edit_change_day change_start_end_day finish_reservation 
      add_non_uofm_passengers update_passengers destroy cancel_recurring_reservation 
      is_in_reservation is_reservation_driver is_reserved_by]) }
  end

  context 'with student role' do
    subject { described_class.new({ user: user_student, role: "student", params: {unit_id: program.unit.id} }, reservation_student) }
    it { is_expected.to forbid_actions(%i[is_super_admin is_admin is_manager user_in_access_group add_drivers_later index week_calendar
      day_reservations approve_all_recurring selected_reservations send_email_to_selected_reservations send_reservation_updated_email]) }
    it { is_expected.to permit_only_actions(%i[is_student show create new new_long update edit edit_long 
      get_available_cars get_available_cars_long no_car_all_times edit_change_day change_start_end_day finish_reservation 
      add_non_uofm_passengers update_passengers destroy cancel_recurring_reservation 
      is_in_reservation is_reservation_driver is_reserved_by]) }
  end

  context 'with no role' do
    subject { described_class.new({ user: user_none, role: "none", params: {unit_id: program.unit.id} }, reservation_admin) }

    it { is_expected.to forbid_all_actions }
  end

end
