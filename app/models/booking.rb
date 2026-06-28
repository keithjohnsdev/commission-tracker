class Booking < ApplicationRecord
  belongs_to :advisor
  delegate :agency, to: :advisor          # booking.agency → advisor's agency

  validates :supplier_name, :trip_name, presence: true
  validates :total_amount,
            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :commission_rate,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 },
            allow_nil: true
  # --- business logic ---
  def effective_rate
    commission_rate || agency&.default_commission_rate || 0
  end

  def expected_commission
    return 0 if total_amount.blank?
    (total_amount * effective_rate).round(2)
  end

  # --- scopes (reusable queries) ---
  scope :received, -> { where(commission_received: true) }
  scope :pending,  -> { where(commission_received: false) }
end
