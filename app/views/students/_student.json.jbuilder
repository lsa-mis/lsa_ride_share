json.extract! student, :id, :uniqname, :last_name, :first_name, :mvr_expiration_date, :class_training_date, :canvas_course_complete_date, :meeting_with_admin_date, :created_at, :updated_at
json.url student_url(student, format: :json)
