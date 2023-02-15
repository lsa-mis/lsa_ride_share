json.extract! vehicle_report, :id, :reservation_id, :mileage_start, :mileage_end, :gas_start, :gas_end, :parking_spot, :created_by, :updated_by, :status, :created_at, :updated_at
json.url vehicle_report_url(vehicle_report, format: :json)
