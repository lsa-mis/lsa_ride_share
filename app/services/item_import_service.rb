require 'csv'
require 'set'

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
        # is the program exist in the term ?
        program = row['PROGRAM'].strip
        term = row["TERM"].strip
        return unless program_exists_for_unit_and_term?(program, term)
        # is the unit exist ?
        # does the program belong to the unit ?
        # does the site belongs to the program ?
        site = row['SITE'].strip
        return unless site_exists_and_belongs_to_program?(site, program)
        # validate start date, time and end date, time
        start_day = row['START DAY'].strip
        end_day = row['END DAY'].strip
        start_time = row['START TIME'].strip
        end_time = row['END TIME'].strip
        return unless valid_start_and_end_time?(start_day, end_day, start_time, end_time)
        # validate the car (if provided) belongs to the unit, has enough seats and is available
        car = row['CAR'].strip
        number_of_people = row['NUMBER OF PEOPLE'].strip
        return unless car_exists_belongs_to_unit_and_available?(car, number_of_people)
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

  def program_exists_for_unit_and_term?(program_title, term_name)
    # TODO: allow both title or id program+term entries
    program = Program.find_by(title: program_title, unit_id: @unit_id)
    unless program
      @errors += 1
      @notes << "Program '#{program_title}' not found for unit #{@unit_id}."
      return false
    end

    term = Term.find_by(name: term_name)
    unless program.term_id == term.id
      @errors += 1
      @notes << "Program '#{program_title}' does not belong to specified term."
      return false
    end

    @current_program = program
    true
  end

  def site_exists_and_belongs_to_program?(site_title, program_title)
    # TODO: allow both title or id program+site entries
    site = Site.find_by(title: site_title, unit_id: @unit_id)
    unless site
      @errors += 1
      @notes << "Site '#{site_title}' not found for unit #{@unit_id}."
      return false
    end

    linked = ProgramsSite.exists?(program_id: @current_program&.id, site_id: site.id)
    unless linked
      @errors += 1
      @notes << "Site '#{site_title}' is not linked to program '#{program_title}'."
      return false
    end

    @current_site = site
    true
  end

  def valid_start_and_end_time?(start_day, end_day, start_time, end_time)
    # TODO: Rita checks for daylight savings
    s_combined = "#{start_day} #{start_time}"
    e_combined = "#{end_day} #{end_time}"
    
    begin
      s_time = Time.parse(s_combined).to_datetime - 15.minute
    rescue ArgumentError
      @errors += 1
      @notes << "Invalid time format for '#{start_day}' or '#{start_time}'."
      return false
    end
    begin
      e_time = Time.parse(e_combined).to_datetime + 15.minute
    rescue ArgumentError
      @errors += 1
      @notes << "Invalid time format for '#{end_day}' or '#{end_time}'."
      return false
    end

    if e_time < s_time
      @errors += 1
      @notes << "End time is too close to start time."
      return false
    end

    @start_time, @end_time = s_time, e_time
    true
  end

  def car_exists_belongs_to_unit_and_available?(car_number, number_of_people)
    # TODO: allow both title or id car entries
    return true if car_number.blank?

    car = Car.find_by(car_number: car_number, unit_id: @unit_id)
    unless car
      @errors += 1
      @notes << "Car '#{car_number}' not found or not part of unit #{@unit_id}."
      return false
    end

    if number_of_people > car.number_of_seats
      @errors += 1
      @notes << "Not enough seats."
      return false
    end

    # TODO: make more efficient
    overlap = car.reservations.where("start_time < ? < end_time OR start_time < ? < end_time", @end_time, @start_time).exists?
    if overlap
      @errors += 1
      @notes << "Car '#{car_number}' is already booked between."
      return false
    end

    @current_car = car
    true
  end

  def driver_exists_and_valid_for_program?(driver, program)
    return true if driver_uniqname.blank?

    driver = Student.find_by(uniqname: driver_uniqname, program_id: @current_program&.id)
    unless driver
      # TODO: Rita adds manager program check
      driver = Manager.find_by(uniqname: driver_uniqname, program_id: @current_program&.id)
      unless driver
        @errors += 1
        @notes << "Driver '#{driver_uniqname}' not found for program '#{program_title}'."
        return false
      end
    end

    @current_driver = driver

    # TODO: Rita adds license validation here.
    # Example:
    # unless driver.valid_license?
    #   @errors += 1
    #   @notes << "Driver '#{driver_uniqname}' does not have a valid license."
    #   return false
    # end

    true
  end

  def passengers_exist_and_valid_for_program?(passengers, program)
    return true if passenger_uniqnames.blank?

    uniqnames = passenger_uniqnames.split(',').map(&:strip)
    # TODO: Rita checks for managers as well
    invalid = uniqnames.reject { |u| Student.exists?(uniqname: u, program_id: @current_program&.id) }

    unless invalid.empty?
      @errors += 1
      @notes << "Invalid passengers for program '#{program_title}': #{invalid.join(', ')}"
      return false
    end

    @current_passengers = Student.where(uniqname: uniqnames, program_id: @current_program.id)
    true
  end

  def get_recurring_details_from_row(row)
    # TODO: Implement logic to extract recurring details from the row
    @recurring = nil
  end

  def create_reservation_record
    Reservation.create!(
      program_id: @current_program.id,
      site_id: @current_site.id,
      car_id: @current_car.id,
      start_time: @start_time,
      end_time: @end_time,
      reserved_by: @user.id,
      recurring: @recurring,
      driver: @current_driver.id
    ).tap do |res|
      if @current_passengers.present?
        @current_passengers.each do |p|
          ReservationPassenger.create!(reservation_id: res.id, student_id: p.id)
        end
      end
    end
  rescue => e
    @errors += 1
    @notes << "Error creating reservation: #{e.message}"
    nil
  end

end
