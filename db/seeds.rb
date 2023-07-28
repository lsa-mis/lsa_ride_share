# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

terms = Term.create!([
  {code: "2410", name: "Fall 2022", classes_begin_date: DateTime.new(2022, 8, 29), classes_end_date: DateTime.new(2022, 12, 9) },
  {code: "2420", name: "Winter 2023", classes_begin_date: DateTime.new(2023, 1, 4), classes_end_date: DateTime.new(2023, 4, 18) },
  {code: "2440", name: "Spring/Summer 2023", classes_begin_date: DateTime.new(2023, 5, 2), classes_end_date: DateTime.new(2023, 8, 15) },
  {code: "2430", name: "Spring 2023", classes_begin_date: DateTime.new(2023, 5, 2), classes_end_date: DateTime.new(2023, 6, 23) },
  {code: "2450", name: "Summer 2023", classes_begin_date: DateTime.new(2023, 6, 28), classes_end_date: DateTime.new(2023, 8, 18) },
  {code: "2460", name: "Fall 2023", classes_begin_date: DateTime.new(2023, 8, 28), classes_end_date: DateTime.new(2023, 12, 6) },
  {code: "2470", name: "Winter 2024", classes_begin_date: DateTime.new(2024, 1, 10), classes_end_date: DateTime.new(2024, 4, 16) },
  {code: "2480", name: "Spring 2024", classes_begin_date: DateTime.new(2024, 4, 30), classes_end_date: DateTime.new(2024, 6, 17) },
  {code: "2490", name: "Spring/Summer 2024", classes_begin_date: DateTime.new(2024, 4, 30), classes_end_date: DateTime.new(2024, 8, 13) },
  {code: "2500", name: "Summer 2024", classes_begin_date: DateTime.new(2024, 6, 26), classes_end_date: DateTime.new(2024, 8, 13) },
  {code: "2510", name: "Fall 2024", classes_begin_date: DateTime.new(2024, 8, 26), classes_end_date: DateTime.new(2024, 12, 9)}
])

term_test = Term.find_by(name: "Spring 2023")

# Create a User record
user_test = User.create!(email: "user_test@umich.edu", password: "password", uid: "user_test", uniqname: "user_test", principal_name: "user_test@umich.edu", display_name: "User Test", person_affiliation: "STAFF")
# future_terms = Term.create!([
#   {code: "2520", name: "Winter 2025" },
#   {code: "2530", name: "Spring 2025" },
#   {code: "2540", name: "Spring/Summer 2025" },
#   {code: "2550", name: "Summer 2025" },
#   {code: "2560", name: "Fall 2025" },
#   {code: "2570", name: "Winter 2026" },
#   {code: "2580", name: "Spring 2026"} 
# ])

Unit.create!([
  {name: "Test Unit", ldap_group: "test-unit-rideshare-admins"}
])

test_unit = Unit.find_by(name: "Test Unit")

# create car
test_car = Car.create!(car_number: "1234-Test Car", make: "Toyota", model: "Corolla", color: "yellow", number_of_seats: 4, mileage: 101.30, gas: 80, parking_spot: "301 Liberty", updated_by: user_test.id, status: "available", unit_id: test_unit.id)

UnitPreference.create!([
  { name: "contact_phone", description: "A phone that students can call with questions about cars reservations", on_off: nil, unit_id: test_unit.id, value: "808 453-3245", pref_type: "string" },
  { name: "unit_office", description: "The unit's office number", on_off: nil, unit_id: test_unit.id, value: "123 Main St", pref_type: "string" },
  { name: "reservation_time_begin", description: "The earliest time of the day to pick up cars", on_off: nil, unit_id: test_unit.id, value: "8:00AM", pref_type: "time" },
  { name: "reservation_time_end", description: "The latest time of the day to drop off cars", on_off: nil, unit_id: test_unit.id, value: "5:00PM", pref_type: "time" },
  { name: "notification_email", description: "The email address that system notification emails are sent to", on_off: nil, unit_id: test_unit.id, value: nil, pref_type: "string"}
])

# create a manager
test_manager = Manager.create!(uniqname: "manager_test", first_name: "Test Manager", last_name: "LSA")

# create a program
p1 = Program.create!(title: "Test Program", subject: "Test Subject", catalog_number: "101", class_section: "001", number_of_students: 10, number_of_students_using_ride_share: 10, pictures_required_start: true, pictures_required_end: true, non_uofm_passengers: false, instructor_id: test_manager.id, updated_by: 1, mvr_link: "https://www.google.com", canvas_link: "https://www.google.com", canvas_course_id: 101, term_id: term_test.id, add_managers: true, not_course: false, unit_id: test_unit.id)

# create a site
Site.create!([
  {title: "Test Site", address1: "123 Main St", city: "Ann Arbor", state: "MI", zip_code: "48104", updated_by: 1, unit_id: test_unit.id},
  {title: "Test2 Site2", address1: "567 North St", city: "Saline", state: "MI", zip_code: "48922", updated_by: 1, unit_id: test_unit.id}
])
site_test = Site.find_by(title: "Test Site")

# create a ProgramSite
ProgramsSite.create!(program_id: p1.id, site_id: site_test.id)

# Create a student
s1 = Student.create!(uniqname: "test_student", last_name: "Test", first_name: "Student", canvas_course_complete_date: DateTime.now, mvr_status: "Approved until 2023-08-10", program_id: p1.id)
s2 = Student.create!(uniqname: "test_student1", last_name: "Test1", first_name: "Student1", canvas_course_complete_date: DateTime.now, mvr_status: "Approved until 2023-08-10", program_id: p1.id)
s3 = Student.create!(uniqname: "test_student2", last_name: "Test2", first_name: "Student2", canvas_course_complete_date: DateTime.now, mvr_status: "Approved until 2023-08-10", program_id: p1.id)

# to create a reservation 
reservation_test = Reservation.create!(status: "reserved", program_id: p1.id, site_id: site_test.id, start_time: DateTime.now, end_time: DateTime.now + 3.hour, driver_id: s1.id, driver_phone: "123-456-7890", number_of_people_on_trip: 1, car_id: test_car, updated_by: user_test.id, reserved_by: user_test.id)
