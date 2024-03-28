desc "This will send automated emails to drivers"
task automated_emails_to_drivers: :environment do

  now = DateTime.now
  units = Unit.all

  units.each do |unit|
    puts unit.name
    if UnitPreference.find_by(unit_id: unit.id, name: "send_reminders").on_off
      # one hour reservation reminder
      reservations = Reservation.current_term.where(approved: true).where("start_time BETWEEN ? AND ?", now + 43.minute,  now + 48.minute)
      reservations.each do |reservation|
        ReservationMailer.with(reservation: reservation).one_hour_reminder.deliver_now
      end

      # reminder about vehicle reports 30 minutes after reservations started
      reservations = Reservation.current_term.where(approved: true).where("end_time < ? ", now + 15.minute).where.missing(:vehicle_report)
      reservations.each do |reservation|
        ReservationMailer.with(reservation: reservation).vehicle_report_reminder.deliver_now
      end
    end
  end
end
