# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

terms = Term.create!([
  {code: "2410", name: "Fall 2022", classes_begin_date: DateTime.new(2022, 8, 29), classes_end_date: DateTime.new(2022, 12, 9)},
  {code: "2420", name: "Winter 2023", classes_begin_date: DateTime.new(2023, 1, 4), classes_end_date: DateTime.new(2023, 4, 18)},
  {code: "2440", name: "Spring/Summer 2023", classes_begin_date: DateTime.new(2023, 5, 2), classes_end_date: DateTime.new(2023, 8, 15)},
  {code: "2430", name: "Spring 2023", classes_begin_date: DateTime.new(2023, 5, 2), classes_end_date: DateTime.new(2023, 6, 23)},
  {code: "2450", name: "Summer 2023", classes_begin_date: DateTime.new(2023, 6, 28), classes_end_date: DateTime.new(2023, 8, 18)},
  {code: "2460", name: "Fall 2023", classes_begin_date: DateTime.new(2023, 8, 28), classes_end_date: DateTime.new(2023, 12, 6)},
  {code: "2470", name: "Winter 2024", classes_begin_date: DateTime.new(2024, 1, 10), classes_end_date: DateTime.new(2024, 4, 16)},
  {code: "2480", name: "Spring 2024", classes_begin_date: DateTime.new(2024, 4, 30), classes_end_date: DateTime.new(2024, 6, 17)},
  {code: "2490", name: "Spring/Summer 2024", classes_begin_date: DateTime.new(2024, 4, 30), classes_end_date: DateTime.new(2024, 8, 13)},
  {code: "2500", name: "Summer 2024", classes_begin_date: DateTime.new(2024, 6, 26), classes_end_date: DateTime.new(2024, 8, 13)},
  {code: "2510", name: "Fall 2024", classes_begin_date: DateTime.new(2024, 8, 26), classes_end_date: DateTime.new(2024, 12, 9)}
])
# future_terms = Term.create!([
#   {code: "2520", name: "Winter 2025"},
#   {code: "2530", name: "Spring 2025"},
#   {code: "2540", name: "Spring/Summer 2025"},
#   {code: "2550", name: "Summer 2025"},
#   {code: "2560", name: "Fall 2025"},
#   {code: "2570", name: "Winter 2026"},
#   {code: "2580", name: "Spring 2026"} 
# ])

Unit.create!(name: "Psychology", ldap_group: "psych.transportation")
Unit.create!(name: "Residential College", ldap_group: "rc-rideshare-admins-test")
Unit.create!(name: "Test Unit", ldap_group: "test-unit-rideshare-admins")

