# Step 08 — Dashboard & Reconciliation (roll-ups + a "commission received" toggle)

## Goal
Build a small **agency dashboard** that rolls up the numbers — total bookings, expected commission, **received vs. outstanding** — and add a one-click **"mark commission received"** toggle on each booking that flips state and updates the roll-ups **live** via Turbo Stream. This ties Steps 04–06 together into something that looks like a real back-office tool.

## Why this matters
Reconciliation — *"which commissions have we actually been paid, and what's still outstanding?"* — is the unglamorous core of a commission tracker, and it's a real part of Tern's domain. This step shows you can (1) write **roll-up queries with scopes**, (2) compose a page from **partials**, and (3) wire a **stateful toggle** with a Turbo Stream — i.e. combine everything so far into a coherent feature, not just isolated demos.

> Tern parallel: a host reconciling supplier payments — every booking is "expected," then "received" once the supplier pays. The dashboard's **outstanding** number is the money still owed to the agency.

---

## Step 1 — Add reconciliation scopes & roll-up methods to the model

You already have `received` / `pending` scopes (Step 04). Add roll-up helpers to `Agency` so the dashboard stays skinny (**fat model, skinny controller**).

`app/models/agency.rb`:
```ruby
class Agency < ApplicationRecord
  has_many :advisors, dependent: :destroy
  has_many :bookings, through: :advisors

  def expected_commission_total
    bookings.sum(&:expected_commission)        # Ruby-level sum (computed value)
  end

  def received_commission_total
    bookings.received.sum(&:expected_commission)
  end

  def outstanding_commission_total
    expected_commission_total - received_commission_total
  end

  # ... existing validations ...
end
```

> These reuse the `received` scope from Step 04. Keeping the math in the model means the dashboard, the API (if you ever add one), and the console all get the same numbers — one source of truth.

---

## Step 2 — A dashboard route, controller, and view

Generate a controller for the dashboard (no model — it's a read-only view):
```bash
bin/rails generate controller Dashboards show
```

Route it. Your `config/routes.rb` currently has flat `resources :bookings / :advisors / :agencies` (and `root` commented out). Make a **surgical** change — nest the dashboard under agencies, leave the other resources alone:
```ruby
resources :agencies do
  resource :dashboard, only: :show     # → /agencies/:agency_id/dashboard, helper: agency_dashboard_path
end
resources :advisors
resources :bookings
# (optional) root "agencies#index"     # currently commented out in your repo
```
This gives the `agency_dashboard_path(agency)` helper the Step 09 system test relies on.

`app/controllers/dashboards_controller.rb`:
```ruby
class DashboardsController < ApplicationController
  def show
    @agency   = Agency.find(params[:agency_id])
    @bookings = @agency.bookings.includes(advisor: :agency)   # eager-load → no N+1
  end
end
```

> **`includes(advisor: :agency)`** is the N+1 fix from Steps 03–04 made real: the dashboard sums computed commissions across many bookings, each of which touches `advisor` and `agency`. Eager-loading turns dozens of queries into a couple. Point this out — it's a concrete senior signal.

`app/views/dashboards/show.html.erb`:
```erb
<h1><%= @agency.name %> — Commission Dashboard</h1>

<%= turbo_stream_from @agency %>   <%# live updates from broadcasts (Step 06) %>

<div id="agency_<%= @agency.id %>_rollup">
  <%= render "dashboards/rollup", agency: @agency %>
</div>

<h2>Bookings</h2>
<div id="bookings">
  <%= render @bookings %>
</div>
```

`app/views/dashboards/_rollup.html.erb` (the partial we'll re-render on changes):
```erb
<dl class="rollup">
  <dt>Bookings</dt>          <dd><%= agency.bookings.count %></dd>
  <dt>Expected</dt>         <dd><%= number_to_currency(agency.expected_commission_total) %></dd>
  <dt>Received</dt>         <dd><%= number_to_currency(agency.received_commission_total) %></dd>
  <dt>Outstanding</dt>      <dd><%= number_to_currency(agency.outstanding_commission_total) %></dd>
</dl>
```

Visit `/agencies/1/dashboard` → a roll-up plus the booking list.

> **Two total surfaces — keep them straight.** Step 06 put a simple total on the **agency show** page with id `agency_<id>_total` (partial `agencies/_total`). This dashboard uses a richer roll-up with id `agency_<id>_rollup` (partial `dashboards/_rollup`). They are **separate ids on separate pages**, so a stream targeting one never touches the other: `create.turbo_stream.erb` (Step 06) replaces `…_total`; the toggle and broadcasts below replace `…_rollup`. (If you'd rather maintain one surface, point the dashboard at `agencies/_total`/`…_total` and drop the rollup — but the dashboard genuinely shows more, so keeping both is reasonable. Just don't expect a `…_total` stream to update the dashboard, or vice-versa.)

---

## Step 3 — A "mark received" toggle (a member route + Turbo Stream)

Add a non-CRUD action that flips `commission_received`. It's a **member route** on bookings (acts on one booking, isn't one of the 7 REST defaults).

`config/routes.rb` — extend the bookings resource:
```ruby
resources :bookings do
  patch :toggle_received, on: :member        # → /bookings/:id/toggle_received
end
```

`app/controllers/bookings_controller.rb` — add a `toggle_received` action:
```ruby
def toggle_received
  @booking = Booking.find(params[:id])
  @booking.update!(commission_received: !@booking.commission_received)

  respond_to do |format|
    format.turbo_stream     # → toggle_received.turbo_stream.erb
    format.html { redirect_back fallback_location: bookings_path }
  end
end
```
> Your scaffold finds records via a `set_booking` before_action that uses `params.expect(:id)`. You can either add `toggle_received` to that callback's list (`only: %i[ show edit update destroy toggle_received ]`) and drop the first line, or keep the explicit `Booking.find` shown here — both are fine.

Add the button to the booking partial. In `app/views/bookings/_booking.html.erb`, **inside the frame**, next to the existing `Edit`/`Show` links (before the closing `</div>` and `<% end %>`):
```erb
<%= button_to (booking.commission_received? ? "✓ Received" : "Mark received"),
      toggle_received_booking_path(booking),
      method: :patch,
      class: booking.commission_received? ? "received" : "pending" %>
```

The Turbo Stream response re-renders **the row** and **the roll-up** in one shot. `app/views/bookings/toggle_received.turbo_stream.erb`:
```erb
<%= turbo_stream.replace @booking %>   <%# re-render this booking's frame (uses dom_id) %>

<%= turbo_stream.replace "agency_#{@booking.agency.id}_rollup" do %>
  <%= render "dashboards/rollup", agency: @booking.agency %>
<% end %>
```

**Try it:** on the dashboard, click "Mark received" on a booking. The button flips to "✓ Received" **and** Outstanding drops by that booking's commission — no reload, one click.

> `turbo_stream.replace @booking` works with no explicit target/HTML because the `_booking` partial is wrapped in `turbo_frame_tag dom_id(booking)` (Step 05). Turbo derives the target id and the partial from the record. The frames-and-streams design from earlier steps is paying off here.

Commit:
```bash
git add -A && git commit -m "Dashboard roll-ups + commission-received toggle via Turbo Stream"
```

---

## Step 4 (optional) — Make the roll-up update on *any* booking change

Right now the roll-up updates on the toggle. To also update it when a booking is **created/edited/deleted** elsewhere, broadcast a roll-up replace from the model (Step 06 style):

```ruby
# app/models/booking.rb — these are IN ADDITION to the Step 06 list callbacks
after_save_commit    -> { broadcast_replace_to agency, target: "agency_#{agency.id}_rollup",
                                                partial: "dashboards/rollup", locals: { agency: agency } }
after_destroy_commit -> { broadcast_replace_to agency, target: "agency_#{agency.id}_rollup",
                                                partial: "dashboards/rollup", locals: { agency: agency } }
```
> You'll now have two families of callbacks on `Booking`: the Step 06 ones that broadcast the **list** (`append`/`replace`/`remove` of the row) and these that broadcast the **roll-up**. They target different DOM ids (`bookings` / the row's `dom_id` vs `agency_<id>_rollup`), so they coexist cleanly. `after_save_commit` fires on both create and update — intentional, since any save should refresh the totals.

Now any open dashboard reflects changes live. (This is the "totals need their own broadcast" caveat from Step 06, resolved.)

---

## Things to look out for
- **N+1 on the dashboard is real here.** Summing computed commissions touches each booking's `advisor`/`agency` — `includes(advisor: :agency)` is what keeps it to a couple of queries. This is the single best place in the app to *show* the N+1 fix.
- **Computed totals can't be summed in SQL.** `expected_commission` is Ruby (it has fallback logic), so `bookings.sum(&:expected_commission)` loads records and sums in Ruby. If this ever got slow you'd **denormalize** (store the commission) or push the logic into the query. Name the trade-off.
- **Toggle is `PATCH`, not `GET`.** It changes state, so it must be a non-idempotent-looking verb behind `button_to` (which renders a real form), never a plain link. GET requests shouldn't mutate.
- **Member vs. collection routes.** `on: :member` acts on one record (`/bookings/:id/toggle_received`); `on: :collection` acts on the set (`/bookings/search`). Know the difference.
- **Keep roll-up math in the model.** If the controller or view computes `expected - received`, it'll drift. One method, one truth.

## Check yourself
- [ ] The dashboard shows Bookings / Expected / Received / Outstanding, and the numbers are correct.
- [ ] Clicking "Mark received" flips the button **and** updates Outstanding live, no reload.
- [ ] Explain why the dashboard query uses `includes(advisor: :agency)`.
- [ ] Explain why the toggle is a `PATCH` via `button_to`, not a link.
- [ ] Explain member vs. collection routes.

## Interview talking points
- *"I built a reconciliation dashboard — expected vs. received vs. outstanding — with the roll-up math as scopes and methods on the model, so every surface gets the same numbers (fat model, skinny controller)."*
- *"The 'mark received' toggle is a member `PATCH` route that responds with a Turbo Stream re-rendering both the booking row and the roll-up in one response — stateful UI, one click, no reload."*
- *"Because I'm summing a *computed* commission across many bookings, I eager-load with `includes(advisor: :agency)` to kill the N+1, and I can articulate when I'd denormalize the total instead."*

**Next:** `09-tests-deploy-talking-points.md` — add Minitest coverage, **deploy to a public URL**, and assemble your full interview talking-points map.
