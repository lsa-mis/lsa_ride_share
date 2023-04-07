json.extract! site_contact, :id, :title, :first_name, :last_name, :phone_number, :email, :created_at, :updated_at
json.url site_contact_url(site_contact, format: :json)
