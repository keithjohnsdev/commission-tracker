class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.references :advisor, null: false, foreign_key: true
      t.string :supplier_name
      t.string :trip_name
      t.decimal :total_amount,  precision: 10, scale: 2
      t.decimal :commission_rate, precision: 5, scale: 4
      t.date :travel_date
      t.string :status, default: "pending"
      t.boolean :commission_received, default: false, null: false
      t.timestamps
    end
  end
end
