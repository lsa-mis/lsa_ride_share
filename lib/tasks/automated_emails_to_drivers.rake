desc "This will send automated emails to drivers"
task automated_emails_to_drivers: :environment do

  now = DateTime.now
  units = Unit.all

  puts "run cron job"
  puts now
  puts "--------------------------"

  units.each do |unit|
    puts unit.name
    if UnitPreference.find_by(unit_id: unit.id, name: "send_reminders").on_off
      # one hour reservation reminder
      reservations = Reservation.current_term.where(approved: true).where("start_time BETWEEN ? AND ?", now + 43.minute,  now + 48.minute)
      reservations.each do |reservation|
        # check that email was not sent
        unless EmailLog.find_by(record_id: reservation.id, email_type: "one_hour_reminder").present?
          ReservationMailer.with(reservation: reservation).one_hour_reminder.deliver_now
        end
      end

      # reminder about vehicle reports 30 minutes after reservations started
      reservations = Reservation.current_term.where(approved: true).where("end_time < ? and end_time > ?", now + 16.minute, now - 31.minute).where.missing(:vehicle_report)
      reservations.each do |reservation|
        unless EmailLog.find_by(record_id: reservation.id, email_type: "vehicle_report_reminder").present?
          ReservationMailer.with(reservation: reservation).vehicle_report_reminder.deliver_now
        end
      end
    end
  end
end
