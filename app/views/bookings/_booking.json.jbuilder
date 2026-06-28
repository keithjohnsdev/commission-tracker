json.extract! booking, :id, :advisor_id, :supplier_name, :trip_name, :total_amount, :commission_rate, :travel_date, :status, :commission_received, :created_at, :updated_at
json.url booking_url(booking, format: :json)
