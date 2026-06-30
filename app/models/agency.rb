class Agency < ApplicationRecord
  has_many :advisors, dependent: :destroy
  has_many :bookings, through: :advisors    # ← the "reach across" association

  def expected_commission_total
    bookings.sum(&:expected_commission)        # Ruby-level sum (computed value)
  end

  def received_commission_total
    bookings.received.sum(&:expected_commission)
  end

  def outstanding_commission_total
    expected_commission_total - received_commission_total
  end

  validates :name, presence: true
  validates :default_commission_rate,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 },
            allow_nil: true
end
