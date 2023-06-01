json.extract! reservation, :id, :status, :start_time, :end_time, :recurring, :driver_phone, :backup_driver_phone, :number_of_people_on_trip, :created_at, :updated_at
json.url reservation_url(reservation, format: :json)
