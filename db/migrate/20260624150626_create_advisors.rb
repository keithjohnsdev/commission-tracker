class CreateAdvisors < ActiveRecord::Migration[8.1]
  def change
    create_table :advisors do |t|
      t.string :name
      t.string :email
      t.references :agency, null: false, foreign_key: true

      t.timestamps
    end
  end
end
