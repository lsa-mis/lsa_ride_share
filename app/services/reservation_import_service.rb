require 'csv'
require 'set'

class ReservationImportService
  attr_reader :file, :unit_id, :user
  include ApplicationHelper

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
        term_id = row['TERM ID']&.strip
        term_name = row["TERM NAME"]&.strip
        term = Term.find_by(id: term_id) || Term.find_by(name: term_name)
        unless term
          @errors += 1
          @notes << "Term #{term_name} or ##{term_id} not found."
          next
        end
        program_id = row['PROGRAM ID']&.strip
        program_title = row['PROGRAM TITLE']&.strip
 
        @program = program_exists_for_unit_and_term?(program_id, program_title, term)
        next unless @program
        # is the unit exist ?
        # does the program belong to the unit ?
        # does the site belongs to the program ?
        site_id = row['SITE ID']&.strip
        site_title = row['SITE TITLE']&.strip
        site = site_exists_and_belongs_to_program?(site_id, site_title)
        next unless site
        # validate start date, time and end date, time
        start_day = row['START DATE']&.strip
        end_day = row['END DATE']&.strip
        start_time = row['START TIME']&.strip
        end_time = row['END TIME']&.strip
        next unless valid_start_and_end_time?(start_day, end_day, start_time, end_time)
        # validate the car (if provided) belongs to the unit, has enough seats and is available
        @number_of_people_on_trip = row['NUMBER OF PEOPLE ON TRIP']&.strip.to_i
        # check if the reservation is recurring (finish_reservation method in reservation_controller)
        recurring = get_recurring_details_from_row(row)
        car_id = row['CAR ID']&.strip
        car_number = row['CAR NUMBER']&.strip
        car = car_exists_belongs_to_unit_and_available(car_id, car_number, @number_of_people_on_trip)
        @reservation = create_reservation_record(@program, site, car, @start_time, @end_time, @number_of_people_on_trip, @until_date, recurring)
        # validate the driver (if provided) belongs to the program and is valid driver
        driver = row['DRIVER']&.strip
        add_driver_to_reservation(driver)
        # validate the passengers (if provided) belong to the program
        passengers = row['PASSENGERS']&.strip
        add_passengers_to_reservation(passengers)
        if recurring.present?
          conflict_days_message = create_recurring_reservations(@reservation, recurring, row)
          if conflict_days_message.present?
            @notes << "Recurring reservation ID #{@reservation.id} has conflicts on the following days: #{conflict_days_message}"
          end
        end
        # send confirmation emails
      end
      # cleanup_removed_items
    }
    task_time = ((total_time.real / 60) % 60).round(2)
    @log.import_logger.info("*********************** Reservations import completed. Total time: #{task_time} minutes.")
    @notes << "Reservations import completed. File: #{@file.original_filename}. Total time: #{task_time} minutes."
    @result[:errors] = @errors
    @result[:note] = @notes
    return @result
    # rescue => e
    #   @log.import_logger.error("***********************Error importing Item: #{e.message}")
    #   @notes << "Occurrence import: Error importing Item. Error: #{e.message}"
    #   @result[:errors] = @errors + 1
    #   @result[:note] = @notes.reverse
    #   return @result
  end

  private

  def program_exists_for_unit_and_term?(program_id, program_title, term)
    program = Program.find_by(id: program_id, unit_id: @unit_id) || Program.find_by(title: program_title, unit_id: @unit_id)
    unless program
      @errors += 1
      @notes << "Program ##{program_title} or ##{program_id} not found for unit."
      return false
    end
    unless program.term_id == term.id
      @errors += 1
      @notes << "Program #{program.title} does not belong to term ##{term.name}."
      return false
    end
    return program
  end

  def site_exists_and_belongs_to_program?(site_id, site_title)
    site = Site.find_by(id: site_id, unit_id: @unit_id) || Site.find_by(title: site_title, unit_id: @unit_id)
    unless site
      @errors += 1
      @notes << "Site ##{site_title} or ##{site_id} not found for unit."
      return false
    end

    if @program.sites.include?(site)
      return site
    else
      @errors += 1
      @notes << "Site ##{site.title} is not added to program ##{@program.title}."
      return false
    end

  end

  def valid_start_and_end_time?(start_day, end_day, start_time, end_time)
    # TODO: Rita checks for daylight savings
    s_combined = "#{start_day} #{start_time}"
    e_combined = "#{end_day} #{end_time}"
    begin
      s_time = Time.zone.strptime(s_combined, "%m/%d/%Y %l:%M %p").to_datetime - 15.minutes
    rescue ArgumentError
      @errors += 1
      @notes << "Invalid time format for start time."
      return false
    end
    begin
      e_time = Time.zone.strptime(e_combined, "%m/%d/%Y %l:%M %p").to_datetime + 15.minutes
    rescue ArgumentError
      @errors += 1
      @notes << "Invalid time format for end time."
      return false
    end

    # validate start_time and end_time comparing to Unit preferences: reservation_time_begin and reservation_time_end
    reservation_time_begin = UnitPreference.find_by(name: "reservation_time_begin", unit_id: @unit_id).value
    reservation_time_end = UnitPreference.find_by(name: "reservation_time_end", unit_id: @unit_id).value
    
    # Parse time strings to Time objects for comparison
    start_time_parsed = Time.strptime(start_time, "%l:%M %p")
    end_time_parsed = Time.strptime(end_time, "%l:%M %p")
    reservation_begin_parsed = Time.strptime(reservation_time_begin, "%l:%M %p")
    reservation_end_parsed = Time.strptime(reservation_time_end, "%l:%M %p")
    
    if start_time_parsed < reservation_begin_parsed
      @errors += 1
      @notes << "Start time #{start_time} is before allowed reservation time #{reservation_time_begin} for unit."
      return false
    end
    if end_time_parsed > reservation_end_parsed
      @errors += 1
      @notes << "End time #{end_time} is after allowed reservation time #{reservation_time_end} for unit."
      return false
    end

    if e_time < s_time
      @errors += 1
      @notes << "End time #{end_time} is too close to start time #{start_time}."
      return false
    end

    @start_time, @end_time = s_time, e_time
  end

  def car_exists_belongs_to_unit_and_available(car_id, car_number, number_of_people_on_trip)
    # 1. check if car exists (id, car_number)
    # 2. check car time available
    # 3. check car available
    # 4. check number of people
    car = Car.find_by(id: car_id, unit_id: @unit_id)
    unless car
      car = Car.find_by(car_number: car_number, unit_id: @unit_id)
      unless car
        @errors += 1
        @notes << "Car #{car_number} or #{car_id} not found or not part of unit."
        return nil
      end
    end

    unless car.status == "available"
      @errors += 1
      @notes << "Car #{car.car_number} status is not available."
      return nil
    end

    unless available?(car, @start_time..@end_time)
      @errors += 1
      @notes << "Car #{car.car_number} is already booked between #{@start_time} and #{@end_time}."
      return nil
    end

    if number_of_people_on_trip > car.number_of_seats
      @errors += 1
      @notes << "Car #{car.car_number} has not enough seats."
      return nil
    end

    return car
  
  end

  def add_driver_to_reservation(driver_uniqname)
    if driver_uniqname.blank?
      @notes << "No driver specified for reservation ID #{@reservation.id}."
      return
    end
    if student_exists_in_program?(driver_uniqname)
      student = Student.find_by(uniqname: driver_uniqname, program_id: @reservation.program_id)
      if student.driver?
        if @reservation.update(driver_id: student.id)
          return
        else
          @errors += 1
          @notes << "Failed to update reservation ID #{@reservation.id}: assign driver '#{driver_uniqname}'."
          return
        end
      else
        @reservation.passengers << student
        @notes << "Student '#{driver_uniqname}' is not a valid driver; added as passenger instead."
      end
    elsif manager_exists_in_program?(driver_uniqname)
      manager = Manager.find_by(uniqname: driver_uniqname)
      if manager.driver?
        if @reservation.update(driver_manager_id: manager.id)
          return
        else
          @errors += 1
          @notes << "Failed to to update reservation ID #{@reservation.id}: assign manager driver '#{driver_uniqname}'."
          return
        end
      else
        @reservation.passengers << manager
        @notes << "Manager '#{driver_uniqname}' is not a valid driver; added as passenger instead."
      end
    end
  end

  def add_passengers_to_reservation(passenger_uniqnames)
    # count number of available passengers spots
    number_of_passengers = (@reservation.driver_id.present? || @reservation.driver_manager_id.present?) ? @reservation.number_of_people_on_trip - 1 : @reservation.number_of_people_on_trip
    # if a driver was added as passenger, reduce number_of_passengers by 1
    if @reservation.passengers.count > 0
      number_of_passengers -= @reservation.passengers.count
    end
    if passenger_uniqnames.blank?
      @notes << "No passengers specified for reservation ID #{@reservation.id}." if number_of_passengers.positive?
      return
    end
    passengers = passenger_uniqnames.split(',').map(&:strip)

    # check that this loop works for all possible cases
    passengers.take(number_of_passengers).each do |uniqname|
      if student_exists_in_program?(uniqname)
        @reservation.passengers << Student.find_by(uniqname: uniqname, program_id: @program.id)
      elsif manager_exists_in_program?(uniqname)
        @reservation.passengers << Manager.find_by(uniqname: uniqname)
      end
    end

    number = number_of_passengers - passengers.size
    case number
    when number > 0
      @notes << "Too few passengers specified for reservation ID #{@reservation.id}. Passengers were added to the reservation"
    when number < 0
      @notes << "Too many passengers specified for reservation ID #{@reservation.id}. Only the first #{number_of_passengers} passengers were added to the reservation"
    end
    
  end

  def student_exists_in_program?(uniqname)
    return false if uniqname.blank?
    unless @program.students.pluck(:uniqname).include?(uniqname)
      @errors += 1
      @notes << "Student '#{uniqname}' is not enrolled in program '#{@program.id}'. Will check managers"
      return false
    end
    true
  end

  def manager_exists_in_program?(uniqname)
    return false if uniqname.blank?
    unless @program.all_managers.include?(uniqname)
      @errors += 1
      @notes << "Manager '#{uniqname}' is not part of program '#{@program.id}'."
      return false
    end
    true
  end

  def get_recurring_details_from_row(row)
    # TODO: Implement logic to extract recurring details from the row
    recurring = row['RECURRING?']&.strip
    unless recurring == 'Yes'
      @until_date = nil
      return nil
    end
    interval = row['REPEAT']&.strip.to_i
    frequency = row['FREQUENCY']
    case frequency
    when 'Daily'
      rule_type = "IceCube::DailyRule"
      validations = {}
    when 'Weekly'
      rule_type = "IceCube::WeeklyRule"
      days_string = row['IF WEEKLY']
      days_numbers = convert_days_to_numbers(days_string)
      validations = {:day=>days_numbers}
    when 'Monthly'
      rule_type = "IceCube::MonthlyRule"
      days_of_month = row['IF MONTHLY']&.split(',').map(&:to_i)
      validations = {:day_of_month=>days_of_month}
    else
      @errors += 1
      @notes << "Invalid frequency '#{frequency}' for recurring reservation."
      recurring = nil
    end
    @until_date = row['UNTIL DATE']&.strip.to_date
    unless @until_date.present?
      @until_date = max_day_for_reservation(@unit_id)
    end
    recurring = {:validations=>validations, :rule_type=>rule_type, :interval=>interval}
  end

  def convert_days_to_numbers(days_string)
    return [] if days_string.blank?
    
    day_mapping = {
      'sunday' => 0, 'monday' => 1, 'tuesday' => 2, 'wednesday' => 3,
      'thursday' => 4, 'friday' => 5, 'saturday' => 6
    }
    
    days_string.split(',').map(&:strip).map(&:downcase).map { |day| day_mapping[day] }.compact
  end

  def create_reservation_record(program, site, car, start_time, end_time, number_of_people_on_trip, until_date, recurring)
    car_id = car.present? ? car.id : nil
    reservation = Reservation.new(
      program_id: program.id,
      site_id: site.id,
      car_id: car_id,
      start_time: start_time,
      end_time: end_time,
      reserved_by: @user.id,
      number_of_people_on_trip: number_of_people_on_trip,
      until_date: until_date,
      recurring: recurring
    )
    unless reservation.save
      @errors += 1
      @notes << "Error creating reservation: #{reservation.errors.full_messages.join(', ')}"
      return nil
    end
    return reservation
    # rescue => e
    #   @errors += 1
    #   @notes << "Error creating reservation: #{e.message}"
    #   nil
  end

  def create_recurring_reservations(reservation, recurring, row)
    recurring_reservation = RecurringReservation.new(reservation)
    conflict_days_message = recurring_reservation.create_all
    return conflict_days_message
  end

end
