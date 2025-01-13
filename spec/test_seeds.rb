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
  {code: "2510", name: "Fall 2024", classes_begin_date: DateTime.new(2024, 8, 26), classes_end_date: DateTime.new(2025, 01, 7)},
  {code: "2510", name: "Winter 2025", classes_begin_date: DateTime.new(2025, 1, 8), classes_end_date: DateTime.new(2025, 5, 5)}
])

Unit.create(name: "Fake Unit", ldap_group: "fake_group")

test_unit = Unit.first

UnitPreference.create!([
  { name: "contact_phone", description: "A phone that students can call with questions about cars reservations", on_off: false, unit_id: test_unit.id, value: "808 453-3245", pref_type: "string" },
  { name: "unit_office", description: "The unit's office number", on_off: false, unit_id: test_unit.id, value: "123 Main St", pref_type: "string" },
  { name: "reservation_time_begin", description: "The earliest time of the day to pick up cars", on_off: false, unit_id: test_unit.id, value: "8:00AM", pref_type: "time" },
  { name: "reservation_time_end", description: "The latest time of the day to drop off cars", on_off: false, unit_id: test_unit.id, value: "5:00PM", pref_type: "time" },
  { name: "notification_email", description: "The email address that system notification emails are sent to", on_off: false, unit_id: test_unit.id, value: "admin@test.com", pref_type: "string"},
  { name: "faculty_survey", description: "Use faculty survey to create programs", on_off: false, unit_id: test_unit.id, value: nil, pref_type: "boolean"},
  { name: "hours_before_reservation", description: "Allow to create reservations without cars", on_off: false, unit_id: test_unit.id, value: "72", pref_type: "integer"},
  { name: "no_car_reservations", description: "The email address that system notification emails are sent to", on_off: false, unit_id: test_unit.id, value: nil, pref_type: "boolean"},
  { name: "parking_location", description: "Comma separated list of parking locations (Add 'Other' at the end of list to allow other locations)", on_off: true, unit_id: test_unit.id, value: "Thayer 1A, Thayer 2, Thayer 2A", pref_type: "string"},
  { name: "recurring_until", description: "A default date to create recurring reservations until in 'yyyy-mm-dd' format", on_off: false, unit_id: test_unit.id, value: nil, pref_type: "string"},
  { name: "send_reminders", description: "Send reminders about upcoming reservations and not started vehicle reports", on_off: false, unit_id: test_unit.id, value: nil, pref_type: "string"},
  { name: "unit_email_message", description: "Add message to reservations emails (approval and update drivers emails)", on_off: false, unit_id: test_unit.id, value: nil, pref_type: "string"}
])
