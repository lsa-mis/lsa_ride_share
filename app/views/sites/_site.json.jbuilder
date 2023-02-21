json.extract! site, :id, :title, :address1, :address2, :city, :state, :zip_code, :created_at, :updated_at
json.url site_url(site, format: :json)
