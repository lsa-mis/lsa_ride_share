desc "This will remove parking location from vehicle reports after a term ends"
task remove_parking_from_old_vehicle_reports: :environment do
  # the script runs on September 1st, January 1 and June 1st
  # on September 1st it removes parking location from Winter term vehicle reports
  # on January 1 it removes parking location from Spring/Summer term vehicle reports
  # on June 1st it removes parking location from Fall term vehicle reports

  @log = ApiLog.new
  now = Date.today
  # now = Date.new(2024, 6, 1)
  @log.api_logger.info "#{now}"
  @log.api_logger.info "remove parking location from vehicle reports ******************************"
  # for testing:
  # now = "Mon, 08 Apr 2024 15:30:00 -0400".to_datetime
  case now
  when ->(d) { d.month == 9 && d.day == 1 }
    # Remove parking location from Winter term vehicle reports
    @log.api_logger.info "Removing parking location from Winter term vehicle reports"
    # find dates of the last Winter term
    @term = Term.where(classes_begin_date: Date.new(now.year, 1, 1).., classes_end_date: ...Date.new(now.year, 6, 1))
  when ->(d) { d.month == 1 && d.day == 1 }
    # Remove parking location from Spring/Summer term vehicle reports
    @log.api_logger.info "Removing parking location from Spring/Summer terms vehicle reports"
    @term = Term.where(classes_begin_date: Date.new(now.year - 1, 4, 1).., classes_end_date: ...Date.new(now.year - 1, 9, 1))
  when ->(d) { d.month == 6 && d.day == 1 }
    # Remove parking location from Fall term vehicle reports
    @log.api_logger.info "Removing parking location from Fall term vehicle reports"
    @term = Term.where(classes_begin_date: Date.new(now.year - 1, 8, 1)..Date.new(now.year - 1, 12, 31), classes_end_date: ...Date.new(now.year, 1, 31))
  else
    @log.api_logger.info "No parking location removal needed"
  end
  if @term.present?
    program_ids = Program.where(term_id: @term.ids).pluck(:id)
    reservation_ids = Reservation.where(program_id: program_ids)
    vehicle_reports =  VehicleReport.where(reservation_id: reservation_ids)

    transaction = ActiveRecord::Base.transaction do
      raise ActiveRecord::Rollback unless vehicle_reports.update_all(parking_spot: "", parking_spot_return: "", parking_note: "", parking_note_return: "")
      true
    end

    if transaction
      @log.api_logger.info "Parking location removed from vehicle reports successfully: " +  @term.pluck(:name).join(", ")
    else
      @log.api_logger.info "Error updating vehicle reports."
    end
  else
    @log.api_logger.info "No term found for parking location removal."
  end

end
