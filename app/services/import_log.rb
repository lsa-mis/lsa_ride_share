class ImportLog
  def import_logger
    @@import_logger ||= Logger.new("#{Rails.root}/log/import_reservations_data.log")
  end
end
