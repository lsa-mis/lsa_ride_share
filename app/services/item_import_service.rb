require 'csv'
require 'set'

#TODO: change this
class ItemImportService
  attr_reader :file, :collection_id

  def initialize(file, unit_id, user)
    @file = file
    @unit_id = unit_id
    @user = user
    @log = ImportLog.new
    @notes = []
    @errors = 0
    @result = { errors: 0, note: [] }
  end

  # This method is the main entry point for the CSV import process.
  # It reads the CSV file, processes each row, and updates or creates items in the database.
  def call
    total_time = Benchmark.measure {
      @log.import_logger.info("#{DateTime.now} - #{Unit.find(@unit_id).name} - Processing File: #{@file.original_filename}")
      CSV.foreach(@file.path, headers: true) do |row|
        # read a row from the CSV file
        # validate the row data
        # is the program exist in the current term ?
        program = row['PROGRAM'].strip
        return unless program_exists_for_unit_and_current_term?(program)
        # is the unit exist ?
        # does the program belong to the unit ?
        # does the site belongs to the program ?
        site = row['SITE'].strip
        return unless site_exists_and_belongs_to_program?(site, program)
        # validate start_time and end_time
        start_time = row['START_TIME'].strip
        end_time = row['END_TIME'].strip
        return unless valid_start_and_end_time?(start_time, end_time)
        # validate the car (if provided) belongs to the unit, has enough seats and is available
        car = row['CAR'].strip
        return unless car_exists_belongs_to_unit_and_available?(car, start_time, end_time)
        # validate the driver (if provided) belongs to the program and is valid driver
        driver = row['DRIVER'].strip
        return unless driver_exists_and_valid_for_program?(driver, program)
        # validate the passengers (if provided) belong to the program
        passengers = row['PASSENGERS'].strip
        return unless passengers_exist_and_valid_for_program?(passengers, program)
        # create the reservation record
        recurring = get_recurring_details_from_row(row)
        reservation = create_reservation_record(program, site, start_time, end_time, recurring, car, driver, passengers)
        # check if the reservation is recurring (finish_reservation method in reservation_controller)
      end
      # cleanup_removed_items
    }
    task_time = ((total_time.real / 60) % 60).round(2)
    @log.import_logger.info("***********************Occurrence import completed. Total time: #{task_time} minutes.")
    @notes << "Occurrence import completed. File: #{@file.original_filename}. Total time: #{task_time} minutes."
    @result[:errors] = @errors
    @result[:note] = @notes.reverse # Reverse to maintain order of processing
    return @result
    # rescue => e
    #   @log.import_logger.error("***********************Error importing Item: #{e.message}")
    #   @notes << "Occurrence import: Error importing Item. Error: #{e.message}"
    #   @result[:errors] = @errors + 1
    #   @result[:note] = @notes.reverse
    #   return @result
  end

  private

  def program_exists_for_unit_and_current_term?(program)
    # Implement validation logic here
  end

  def site_exists_and_belongs_to_program?(site, program)
    # Implement validation logic here
  end

  def valid_start_and_end_time?(start_time, end_time)
    # Implement validation logic here
  end

  def car_exists_belongs_to_unit_and_available?(car, start_time, end_time)
    # Implement validation logic here
  end

  def driver_exists_and_valid_for_program?(driver, program)
    # Implement validation logic here
  end

  def passengers_exist_and_valid_for_program?(passengers, program)
    # Implement validation logic here
  end

  def get_recurring_details_from_row(row)
    # Implement logic to extract recurring details from the row
  end

  def create_reservation_record(program, site, start_time, end_time, recurring, car, driver, passengers)
    # Implement logic to create the reservation record
  end

end
