# Step 09 — Tests, Deploy & Your Interview Talking-Points Map

## Goal
Add **Minitest** coverage for the commission logic, **deploy the app to a public URL**, and assemble a **one-page talking-points map** that connects everything you built to the concepts an interviewer will probe. This turns "I followed a tutorial" into "I built, tested, and shipped a small Rails + Hotwire app that models your domain" — a sentence you can say truthfully.

## Why this matters
Two things separate a credible candidate from someone who skimmed docs: **a test that proves the core logic works**, and **a live URL you can pull up**. You don't need exhaustive coverage — you need to *test the thing that matters* (commission math) and *ship*. The talking-points map is your interview cheat sheet: every concept → the concrete thing you built that demonstrates it.

> Tern parallel: commission math is the part you cannot get wrong, so it's the part you test. Shipping to a URL mirrors their "ship weekly" reality.

---

## Step 1 — Test the commission engine (the part that must be correct)

Rails generated test files with each scaffold. Fill in the one that matters — the model logic. Use **fixtures** for sample data.

`test/fixtures/agencies.yml`:
```yaml
wanderlust:
  name: Wanderlust Collective
  default_commission_rate: 0.15
```

`test/fixtures/advisors.yml`:
```yaml
jordan:
  name: Jordan Lee
  email: jordan@example.com
  agency: wanderlust       # references the fixture by name
```

`test/fixtures/bookings.yml`:
```yaml
greek_cruise:
  advisor: jordan
  supplier_name: Aegean Cruise Line
  trip_name: Greek Isles Cruise
  total_amount: 8000.00
  commission_rate: 0.16
  commission_received: false

tuscany:
  advisor: jordan
  supplier_name: Italia Stays
  trip_name: Tuscany Villa Week
  total_amount: 5000.00
  commission_rate:           # nil → falls back to agency default
  commission_received: false
```

`test/models/booking_test.rb`:
```ruby
require "test_helper"

class BookingTest < ActiveSupport::TestCase
  test "expected_commission is amount times rate" do
    booking = bookings(:greek_cruise)
    assert_equal 1280.00, booking.expected_commission   # 8000 * 0.16
  end

  test "effective_rate falls back to the agency default" do
    booking = bookings(:tuscany)
    assert_nil booking.commission_rate
    assert_equal 0.15, booking.effective_rate
    assert_equal 750.00, booking.expected_commission    # 5000 * 0.15
  end

  test "expected_commission is zero with no amount" do
    booking = bookings(:greek_cruise)
    booking.total_amount = nil
    assert_equal 0, booking.expected_commission
  end

  test "rate above 1 is invalid" do
    booking = bookings(:greek_cruise)
    booking.commission_rate = 1.5
    assert_not booking.valid?
    assert_includes booking.errors[:commission_rate], "must be less than or equal to 1"
  end
end
```

Add an agency roll-up test, `test/models/agency_test.rb`:
```ruby
require "test_helper"

class AgencyTest < ActiveSupport::TestCase
  test "outstanding equals expected minus received" do
    agency = agencies(:wanderlust)
    assert_equal agency.expected_commission_total, agency.outstanding_commission_total
    bookings(:greek_cruise).update!(commission_received: true)
    assert_equal 750.00, agency.reload.outstanding_commission_total
  end
end
```

Run the suite:
```bash
bin/rails test
```

> **What to say:** *"I tested the commission engine — the part that has to be correct — including the rate fallback and the validation boundaries, plus a roll-up test for outstanding balance."* That's more convincing than "100% coverage."

---

## Step 2 — One system test (proves the Hotwire flow works end-to-end)

A **system test** drives a real browser (Capybara + headless Chrome) — it verifies the Turbo/Stimulus flow actually works.

`test/system/bookings_test.rb`:
```ruby
require "application_system_test_case"

class BookingsTest < ApplicationSystemTestCase
  test "marking a booking received updates it without a full reload" do
    visit agency_dashboard_path(agencies(:wanderlust))
    assert_text "Greek Isles Cruise"

    within "##{dom_id(bookings(:greek_cruise))}" do
      click_button "Mark received"
      assert_text "✓ Received"     # the Turbo Stream swapped the row in place
    end
  end
end
```
```bash
bin/rails test:system
```
> System tests are slower but they prove the **inline/live** behavior — exactly the Hotwire claims you'll be making. One good one is plenty.

Commit:
```bash
git add -A && git commit -m "Tests: commission engine, roll-ups, and a Hotwire system test"
```

---

## Step 3 — Deploy to a public URL

Pick the path that gets you a live link fastest. Two solid options:

### Option A — Render (simplest; managed Postgres)
1. Push the repo to GitHub.
2. On Render: **New → Blueprint** (or Web Service) pointing at the repo.
3. Add a `render.yaml` (or use the dashboard) for a **web service** + a **Postgres** database.
4. Render sets `DATABASE_URL`; Rails 8's `config/database.yml` reads it in production.
5. Render runs `bundle install`, `bin/rails assets:precompile`, and `bin/rails db:migrate` on deploy; boots with `bin/rails server`.

**SQLite → Postgres note:** you built on SQLite, but most hosts want Postgres (and **Tern uses Postgres**). Add `gem "pg"` to the `production` group, keep `sqlite3` for dev/test, and run `bin/rails db:migrate` on the host. Your migrations are portable — this is mostly a config swap. *(Rails 8 *can* run SQLite in production on a persistent disk, but managed Postgres is the lower-friction, more production-typical choice — and the one that matches Tern.)*

### Option B — Kamal (the Rails 8 native path; needs a server)
Rails 8 ships **Kamal** + **Thruster** preconfigured (`config/deploy.yml`, `Dockerfile` are already generated). Point it at any cheap VPS:
```bash
# set RAILS_MASTER_KEY + registry creds, edit config/deploy.yml (server IP, host)
bin/kamal setup     # first deploy: provisions Docker, pushes image, boots
bin/kamal deploy    # subsequent deploys
```
Kamal is what the Rails core team uses to deploy with zero PaaS. **Mention you know it exists even if you deploy on Render** — it signals you're current with Rails 8.

> Either way, set `RAILS_MASTER_KEY` (from `config/master.key`) as an env var on the host so it can decrypt credentials. **Never commit `master.key`.**

Run migrations + seed on the host, then open the URL and click through. **You now have a portfolio link.**

---

## Step 4 — Your interview talking-points map

The deliverable. Each concept → the concrete thing you built. Read it out loud.

| If they ask about… | You built / can say |
|---|---|
| **MVC / Rails philosophy** | Full CRUD via scaffolding; convention over configuration; "the framework makes the 80% case trivial so I focus on domain logic." |
| **Active Record / ORM** | Models, migrations, validations; `decimal` for money (never float); `find_or_create_by!` idempotent seeds. |
| **Associations** | `belongs_to`/`has_many` (Advisor↔Agency); **`has_many :through`** (Agency→Bookings via Advisors); foreign keys; `dependent:`. |
| **Business logic** | `expected_commission` = amount × rate with **agency-default fallback**, in the model (fat model, skinny controller); scopes (`received`/`pending`). |
| **Performance / SQL** | **N+1** and `includes(advisor: :agency)`; SQL-`sum` vs Ruby-`sum` for computed values; when to denormalize. |
| **Turbo Drive** | SPA-like nav for free — body swaps, no full reloads. |
| **Turbo Frames** | **Inline-edit a booking** with no reload — matching frame-id contract, `dom_id`, zero JS. |
| **Turbo Streams** | Live list + roll-up totals in **one response**; **broadcast** over Action Cable to every tab; `after_*_commit`; scoped per agency. |
| **Stimulus** | **Live commission calculator** — targets/actions/values, client-side, no round-trip; client value isn't authoritative. |
| **Hotwire vs. React** | "HTML over the wire — server owns rendering; Stimulus for sprinkles. Less JS, fewer moving parts, ships fast — right for a lean team." |
| **Reconciliation** | Dashboard roll-ups (expected/received/outstanding); `PATCH` member-route toggle via Turbo Stream. |
| **Testing** | Minitest on the commission engine (fallback + validation boundaries) + one system test for the Hotwire flow. |
| **Deploy / ops** | Live on Render (or Kamal); **SQLite (dev) → Postgres (prod, like Tern)**; `RAILS_MASTER_KEY`, migrations on deploy. |
| **Tern domain fit** | "I modeled host→advisor→booking→commission with roll-ups — your actual problem — and shipped it." |

---

## Things to look out for
- **Test the logic, not the framework.** Don't test that `belongs_to` works — test *your* commission math and its edge cases (nil amount, fallback rate, rate > 1).
- **`master.key` is a secret.** It's git-ignored by default; set it as an env var on the host. Leaking it leaks all encrypted credentials.
- **Run migrations on deploy**, every deploy. A forgotten migration is the classic "works locally, 500s in prod."
- **SQLite vs Postgres parity.** They're close, but if you develop on SQLite and deploy on Postgres, run your tests against the prod DB engine before relying on edge behavior (column types, case sensitivity).
- **Assets in production.** `assets:precompile` must run on deploy (Render/Kamal do this); a blank-looking prod app is usually a missed precompile.

## Check yourself
- [ ] `bin/rails test` is green, including the commission-engine and roll-up tests.
- [ ] One system test proves the Hotwire toggle works end-to-end.
- [ ] The app is live at a public URL you can open in the interview.
- [ ] You can recite the talking-points map — concept → thing you built — without notes.
- [ ] You can explain the SQLite→Postgres switch and why Tern uses Postgres.

## Interview talking points
- *"I tested the part that has to be correct — the commission engine, including the rate fallback and validation boundaries — plus one system test that proves the Turbo Stream toggle works end-to-end. I test logic, not the framework."*
- *"I shipped it to a public URL. I built on SQLite for speed and deploy on Postgres, which is what Tern runs — the migrations are portable, so it's mostly a config swap, and I keep the master key out of git as an env var."*
- *"The whole app mirrors your domain — host agency → advisors → bookings → commission roll-ups, with live reconciliation — built on Rails 8 + Hotwire. I can pull it up right now."*

---

## You're done — what you can now say, truthfully
> *"I built and deployed a small Rails 8 + Hotwire app that models a host agency's advisors, bookings, and multi-layer commissions — with `has_many :through` roll-ups, inline editing via Turbo Frames, live totals via Turbo Streams (including broadcasts), a Stimulus commission calculator, a reconciliation dashboard, tests on the commission engine, and a Postgres deploy. It's the same shape as Tern's problem, and it's live."*

Read that out loud. That's the interview.
