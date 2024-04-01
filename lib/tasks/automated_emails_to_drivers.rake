desc "This will send automated emails to drivers"
task automated_emails_to_drivers: :environment do

  now = DateTime.now
  # now = "Sun, 31 Mar 2024 17:30:54 -0400".to_datetime
  units = Unit.all

  puts "--------------------------"
  puts now

  units.each do |unit|
    puts unit.name
    if UnitPreference.find_by(unit_id: unit.id, name: "send_reminders").on_off
      puts "preference on"
      # one hour reservation reminder
      reservations = Reservation.current_term.where(approved: true).where("start_time BETWEEN ? AND ?", now + 43.minute,  now + 48.minute)
      reservations.each do |reservation|
        puts reservation.id
        # check that email was not sent
        unless EmailLog.find_by(record_id: reservation.id, email_type: "one_hour_reminder").present?
          puts "send_reminders"
          ReservationMailer.with(reservation: reservation).one_hour_reminder.deliver_now
        end
      end

      # reminder about vehicle reports 30 minutes after reservations started
      reservations = Reservation.no_or_not_complete_vehicle_reports.where(approved: true).where("end_time BETWEEN ? AND ?", now - 18.minute, now - 12.minute)
      # reservations = Reservation.current_term.where(approved: true).where("end_time BETWEEN ? AND ?", now - 18.minute, now - 12.minute).where.missing(:vehicle_report)
      reservations.each do |reservation|
        uts reservation.id
        unless EmailLog.find_by(record_id: reservation.id, email_type: "vehicle_report_reminder").present?
          puts "vehicle_report_reminder"
          ReservationMailer.with(reservation: reservation).vehicle_report_reminder.deliver_now
        end
      end
    end
  end
  puts "--------------------------"
end
