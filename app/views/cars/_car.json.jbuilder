json.extract! car, :id, :car_number, :make, :model, :color, :number_of_seats, :mileage, :gas, :parking_spot, :last_used, :last_checked, :last_driver, :created_at, :updated_at
json.url car_url(car, format: :json)
