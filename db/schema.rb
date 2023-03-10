# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_02_28_010403) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_accesses", force: :cascade do |t|
    t.string "department"
    t.string "ldap_group"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cars", force: :cascade do |t|
    t.string "car_number"
    t.string "make"
    t.string "model"
    t.string "color"
    t.integer "number_of_seats"
    t.float "mileage"
    t.float "gas"
    t.string "parking_spot"
    t.datetime "last_used"
    t.datetime "last_checked"
    t.integer "last_driver"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cars_programs", force: :cascade do |t|
    t.bigint "car_id", null: false
    t.bigint "program_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["car_id"], name: "index_cars_programs_on_car_id"
    t.index ["program_id"], name: "index_cars_programs_on_program_id"
  end

  create_table "config_questions", force: :cascade do |t|
    t.bigint "program_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["program_id"], name: "index_config_questions_on_program_id"
  end

  create_table "program_managers", force: :cascade do |t|
    t.string "uniqname"
    t.string "first_name"
    t.string "last_name"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "program_id"
    t.index ["program_id"], name: "index_program_managers_on_program_id"
  end

  create_table "program_managers_programs", force: :cascade do |t|
    t.bigint "program_manager_id", null: false
    t.bigint "program_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["program_id"], name: "index_program_managers_programs_on_program_id"
    t.index ["program_manager_id"], name: "index_program_managers_programs_on_program_manager_id"
  end

  create_table "programs", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "title"
    t.string "subject", null: false
    t.string "catalog_number", null: false
    t.string "class_section", null: false
    t.integer "number_of_students"
    t.integer "number_of_students_using_ride_share"
    t.boolean "pictures_required_start", default: false
    t.boolean "pictures_required_end", default: false
    t.boolean "non_uofm_passengers", default: false
    t.bigint "instructor_id", null: false
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "admin_access_id"
    t.string "mvr_link"
    t.string "canvas_link"
    t.integer "canvas_course_id"
    t.integer "term_id"
    t.index ["admin_access_id"], name: "index_programs_on_admin_access_id"
    t.index ["instructor_id"], name: "index_programs_on_instructor_id"
  end

  create_table "programs_sites", force: :cascade do |t|
    t.bigint "program_id", null: false
    t.bigint "site_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["program_id"], name: "index_programs_sites_on_program_id"
    t.index ["site_id"], name: "index_programs_sites_on_site_id"
  end

  create_table "programs_students", force: :cascade do |t|
    t.bigint "program_id", null: false
    t.bigint "student_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["program_id"], name: "index_programs_students_on_program_id"
    t.index ["student_id"], name: "index_programs_students_on_student_id"
  end

  create_table "reservation_passengers", force: :cascade do |t|
    t.bigint "reservation_id", null: false
    t.bigint "student_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reservation_id"], name: "index_reservation_passengers_on_reservation_id"
    t.index ["student_id"], name: "index_reservation_passengers_on_student_id"
  end

  create_table "reservations", force: :cascade do |t|
    t.string "status"
    t.bigint "program_id", null: false
    t.bigint "site_id", null: false
    t.bigint "car_id"
    t.datetime "start_date"
    t.datetime "end_date"
    t.string "recurring"
    t.bigint "driver_id"
    t.string "driver_phone"
    t.bigint "backup_driver_id"
    t.string "backup_driver_phone"
    t.integer "number_of_people_on_trip"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "reserved_by"
    t.index ["backup_driver_id"], name: "index_reservations_on_backup_driver_id"
    t.index ["car_id"], name: "index_reservations_on_car_id"
    t.index ["driver_id"], name: "index_reservations_on_driver_id"
    t.index ["program_id"], name: "index_reservations_on_program_id"
    t.index ["site_id"], name: "index_reservations_on_site_id"
  end

  create_table "sites", force: :cascade do |t|
    t.string "title"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "state"
    t.string "zip_code"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "students", force: :cascade do |t|
    t.string "uniqname"
    t.string "last_name"
    t.string "first_name"
    t.date "mvr_expiration_date"
    t.date "class_training_date"
    t.date "canvas_course_complete_date"
    t.string "meeting_with_admin_date"
    t.integer "updated_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "terms", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.date "term_start"
    t.date "term_end"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uid"
    t.string "uniqname"
    t.string "principal_name"
    t.string "display_name"
    t.string "person_affiliation"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vehicle_reports", force: :cascade do |t|
    t.bigint "reservation_id", null: false
    t.float "mileage_start"
    t.float "mileage_end"
    t.float "gas_start"
    t.float "gas_end"
    t.string "parking_spot"
    t.integer "created_by"
    t.integer "updated_by"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reservation_id"], name: "index_vehicle_reports_on_reservation_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cars_programs", "cars"
  add_foreign_key "cars_programs", "programs"
  add_foreign_key "config_questions", "programs"
  add_foreign_key "program_managers_programs", "program_managers"
  add_foreign_key "program_managers_programs", "programs"
  add_foreign_key "programs", "program_managers", column: "instructor_id"
  add_foreign_key "programs_sites", "programs"
  add_foreign_key "programs_sites", "sites"
  add_foreign_key "programs_students", "programs"
  add_foreign_key "programs_students", "students"
  add_foreign_key "reservation_passengers", "reservations"
  add_foreign_key "reservation_passengers", "students"
  add_foreign_key "reservations", "cars"
  add_foreign_key "reservations", "programs"
  add_foreign_key "reservations", "sites"
  add_foreign_key "reservations", "students", column: "backup_driver_id"
  add_foreign_key "reservations", "students", column: "driver_id"
  add_foreign_key "vehicle_reports", "reservations"
end
