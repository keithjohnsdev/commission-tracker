class CreateAgencies < ActiveRecord::Migration[8.1]
  def change
    create_table :agencies do |t|
      t.string :name
      t.string :iata_number
      t.decimal :default_commission_rate

      t.timestamps
    end
  end
end
