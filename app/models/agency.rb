class Agency < ApplicationRecord
  has_many :advisors, dependent: :destroy
  has_many :bookings, through: :advisors    # ← the "reach across" association

  validates :name, presence: true
  validates :default_commission_rate,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 },
            allow_nil: true
end
