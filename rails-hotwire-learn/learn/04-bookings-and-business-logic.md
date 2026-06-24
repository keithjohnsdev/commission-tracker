# Step 04 — Bookings & Business Logic (the commission engine)

## Goal
Add the **Booking** model (a trip an advisor sold), connect **Agency → Bookings** via **`has_many :through`**, and put real **commission logic** in the model. This completes the data model and teaches model methods, money handling, scopes, and computed values — the substance behind a "commission tracker."

## Why this matters
This is where the app stops being generic CRUD and becomes domain software. Computing **expected commission** and rolling it up to the agency is exactly Tern's core problem. Being able to say *"I put the commission calculation in the model and rolled it up to the agency with `has_many :through`"* is a genuinely strong, specific thing to discuss.

> Tern parallel: a Booking carries a `total_amount` and a `commission_rate`; expected commission = amount × rate; the host's total is the sum across all its advisors' bookings (`04-travel-industry-primer.md`).

---

## Step 1 — Generate the Booking scaffold

```bash
bin/rails generate scaffold Booking advisor:references supplier_name:string \
  trip_name:string total_amount:decimal commission_rate:decimal \
  travel_date:date status:string commission_received:boolean
```

**Before** running `db:migrate`, open the new migration and improve the money columns:

```ruby
class CreateBookings < ActiveRecord::Migration[8.0]
  def change
    create_table :bookings do |t|
      t.references :advisor, null: false, foreign_key: true
      t.string  :supplier_name
      t.string  :trip_name
      t.decimal :total_amount,    precision: 10, scale: 2   # money: up to 99,999,999.99
      t.decimal :commission_rate, precision: 5,  scale: 4   # rate: e.g. 0.1500 = 15%
      t.date    :travel_date
      t.string  :status, default: "pending"
      t.boolean :commission_received, default: false, null: false
      t.timestamps
    end
  end
end
```
Then:
```bash
bin/rails db:migrate
```

**Why `precision`/`scale`:** `decimal` stores exact base-10 numbers (no float rounding). `precision` = total digits, `scale` = digits after the decimal point. `precision: 10, scale: 2` → max `99,999,999.99`. Rates get more decimal places (`scale: 4`) so `0.1500` = 15%. **Money is always decimal (or integer cents), never float** — be ready to say why.

---

## Step 2 — Wire the associations (including `has_many :through`)

`app/models/booking.rb`:
```ruby
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
```

`app/models/advisor.rb` — add bookings:
```ruby
class Advisor < ApplicationRecord
  belongs_to :agency
  has_many :bookings, dependent: :destroy   # ← add

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
```

`app/models/agency.rb` — reach bookings **through** advisors:
```ruby
class Agency < ApplicationRecord
  has_many :advisors, dependent: :destroy
  has_many :bookings, through: :advisors    # ← the "reach across" association

  validates :name, presence: true
  validates :default_commission_rate,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 },
            allow_nil: true
end
```

> **`has_many :bookings, through: :advisors`** lets you write `agency.bookings` even though there's no `agency_id` on bookings — Rails joins through the advisors table. This is the association that models a hierarchy, and it's the one most worth being able to explain for Tern.

---

## Step 3 — Make the booking form usable

In `app/views/bookings/_form.html.erb`, swap the `advisor_id` number field for a dropdown:
```erb
<div>
  <%= form.label :advisor_id, "Advisor" %>
  <%= form.collection_select :advisor_id, Advisor.order(:name), :id, :name,
        { prompt: "Select an advisor" } %>
</div>
```
Optionally make `status` a select:
```erb
<%= form.select :status, ["pending", "traveled", "cancelled"] %>
```

---

## Step 4 — Seed some sample data (so later Hotwire steps have data)

Open `db/seeds.rb` and add:
```ruby
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
```
Load it:
```bash
bin/rails db:seed
```
> `find_or_create_by!` makes seeds **idempotent** — safe to run repeatedly without duplicating. The `!` raises on validation failure so you notice problems.

---

## Step 5 — Explore the commission engine in the console

```bash
bin/rails console
```
```ruby
b = Booking.find_by(trip_name: "Greek Isles Cruise")
b.expected_commission        # => 1280.0  (8000 * 0.16)

b2 = Booking.find_by(trip_name: "Tuscany Villa Week")
b2.commission_rate           # => nil
b2.effective_rate            # => 0.15  (fell back to agency default)
b2.expected_commission       # => 750.0 (5000 * 0.15)

agency = Agency.first
agency.bookings.count                       # reaches through advisors
agency.bookings.sum(:total_amount)          # DB-level sum of a column
agency.bookings.sum(&:expected_commission)  # Ruby-level sum of a computed value
agency.bookings.received.count              # using the scope
exit
```
> Note the two sums: `sum(:total_amount)` runs **in the database** (fast, one query). `sum(&:expected_commission)` loads the records and sums **in Ruby** (because it's computed, not a column). Knowing that distinction = real ORM literacy.

Commit:
```bash
git add -A && git commit -m "Bookings + commission logic, has_many :through, seeds"
```

---

## Things to look out for
- **Money = `decimal` (or integer cents), never `float`.** Floats can't represent `0.1` exactly → rounding errors in commissions. This is the #1 "do you understand money" check.
- **Rate representation:** we store rates as a fraction (`0.15`), not `15`. Pick one convention and validate it (`<= 1`). If you stored percents you'd divide by 100 somewhere — be consistent.
- **Computed vs. stored.** We *compute* `expected_commission` on the fly. Alternative: store it in a column. Trade-off: computing is always correct but can't be queried/summed in SQL directly; storing is queryable but can go stale. Good thing to discuss.
- **`has_many :through` needs the middle association.** `agency.bookings` only works because `Agency has_many :advisors` **and** `Advisor has_many :bookings` both exist.
- **N+1 again:** summing `expected_commission` over many bookings will load each booking's advisor→agency. For our size it's fine; at scale you'd `includes(advisor: :agency)`. Mention it.
- **`delegate :agency, to: :advisor`** is a clean way to expose `booking.agency`; alternatively `has_one :agency, through: :advisor`. Either is fine — know both exist.

## Check yourself
- [ ] `booking.expected_commission` returns amount × rate; a booking with no rate falls back to the agency default.
- [ ] `agency.bookings` works via `has_many :through`.
- [ ] Explain why money is `decimal`, not `float`.
- [ ] Explain the difference between `sum(:total_amount)` (SQL) and `sum(&:expected_commission)` (Ruby).
- [ ] Explain a scope and write one (`received` / `pending`).

## Interview talking points
- *"I reached the agency's bookings with `has_many :bookings, through: :advisors` — there's no `agency_id` on bookings, Rails joins through the advisors table, which mirrors a host→advisor→booking hierarchy."*
- *"Commission logic lives in the model — `expected_commission` is amount × rate, with the rate falling back to the agency default — keeping business rules in one place (fat model, skinny controller)."*
- *"I stored money as `decimal` with explicit precision and scale, never float, to avoid rounding errors — correctness is non-negotiable for commissions."*
- *"I used scopes like `received`/`pending` for reusable queries, and I'm aware of the SQL-sum vs Ruby-sum distinction and N+1 when rolling up computed values."*

**Next (Hotwire begins):** `05-hotwire-turbo-frames.md` — make a booking editable inline without a full page reload. *(Ping me to write 05–09; I'll tailor the Hotwire trio to how the build is feeling.)*
