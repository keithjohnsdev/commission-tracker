# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
#

agency = Agency.find_or_create_by!(name: "Wanderlust Collective") do |a|
  a.iata_number = "12345678"
  a.default_commission_rate = 0.15
end

advisor = agency.advisors.find_or_create_by!(email: "jordan@example.com") do |adv|
  adv.name = "Jordan Lee"
end

advisor.bookings.find_or_create_by!(trip_name: "Greek Isles Cruise") do |b|
  b.supplier_name     = "Aegean Cruise Line"
  b.total_amount      = 8000
  b.commission_rate   = 0.16
  b.travel_date       = Date.today + 60
  b.status            = "pending"
end

advisor.bookings.find_or_create_by!(trip_name: "Tuscany Villa Week") do |b|
  b.supplier_name = "Italia Stays"
  b.total_amount  = 5000          # no rate → falls back to agency default (0.15)
  b.travel_date   = Date.today + 90
end

puts "Seeded: #{Agency.count} agencies, #{Advisor.count} advisors, #{Booking.count} bookings"
