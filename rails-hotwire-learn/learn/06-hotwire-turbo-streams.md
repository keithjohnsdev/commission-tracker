# Step 06 — Hotwire II: Turbo Streams (live lists & roll-up totals)

## Goal
When a booking is **created, updated, or deleted**, update the **bookings list** *and* the agency's **total expected commission** live — first as the **response to the form submit**, then **broadcast** so every open tab updates without anyone refreshing. This is the "live commission tracker" payoff and the most impressive Hotwire piece to demo.

## Why this matters
Turbo **Frames** replace *one* region for *the person who acted*. Turbo **Streams** are more powerful in two ways: (1) **one response can update many regions** (append a row *and* re-render the total), and (2) they can be **broadcast over WebSockets** so updates land in **every connected browser**. That second part — real-time, multi-user, no JavaScript — is exactly the kind of thing that makes a host agency's dashboard feel alive. If you can explain *frames vs. streams* and *request-response vs. broadcast*, you understand Hotwire better than most.

> Tern parallel: an advisor logs a new booking and the host's running commission total ticks up **on the manager's screen too**, instantly. That's a broadcast Turbo Stream.

---

## Step 1 — Put a named, targetable total on the agency page

A Turbo Stream needs a **DOM id to aim at**. Add a roll-up total to the agency's show page, wrapped in an element with a stable id.

`app/views/agencies/show.html.erb` — add near the top:
```erb
<div id="agency_<%= @agency.id %>_total">
  <%= render "agencies/total", agency: @agency %>
</div>
```

Create the partial `app/views/agencies/_total.html.erb`:
```erb
<p>
  <strong>Total expected commission:</strong>
  <%= number_to_currency(agency.bookings.sum(&:expected_commission)) %>
  across <%= agency.bookings.count %> bookings
</p>
```

The wrapper id `agency_42_total` is the **target** a stream will replace. (We render through a partial so the *form response* and the *broadcast* can both reuse the exact same HTML — DRY.)

---

## Step 2 — Stream A: update the list as a response to the form

A **Turbo Stream is a list of actions** wrapped in `<turbo-stream>` tags. Each action names an **operation** (`append`, `prepend`, `replace`, `update`, `remove`, `before`, `after`) and a **target id**, and carries a `<template>` of HTML.

First, make the bookings index a streamable list. `app/views/bookings/index.html.erb`:
```erb
<h1>Bookings</h1>
<div id="bookings">
  <%= render @bookings %>   <%# renders _booking.html.erb per record %>
</div>
<%= link_to "New booking", new_booking_path %>
```

Now teach the controller to answer the **`turbo_stream` format** on create. Rails picks the format from the request; Turbo sends `Accept: text/vnd.turbo-stream.html` for form submits.

`app/controllers/bookings_controller.rb`:
```ruby
def create
  @booking = Booking.new(booking_params)

  respond_to do |format|
    if @booking.save
      format.turbo_stream     # → renders create.turbo_stream.erb
      format.html { redirect_to @booking, notice: "Booking created." }
    else
      format.html { render :new, status: :unprocessable_entity }
    end
  end
end
```

Create `app/views/bookings/create.turbo_stream.erb`:
```erb
<%# 1) add the new row to the list %>
<%= turbo_stream.append "bookings", @booking %>

<%# 2) re-render the agency's total in place %>
<%= turbo_stream.replace "agency_#{@booking.agency.id}_total" do %>
  <%= render "agencies/total", agency: @booking.agency %>
<% end %>
```

**One response, two updates.** `turbo_stream.append "bookings", @booking` appends the rendered `_booking` partial to the `#bookings` list; `turbo_stream.replace` swaps the totals partial. No reload, and the controller stayed skinny.

> `turbo_stream.append "bookings", @booking` is shorthand — Turbo renders the `_booking` partial for you because you passed a record. You can also pass a block of explicit HTML (as in the `replace` above).

---

## Step 3 — Stream B: broadcast to *every* open tab

So far the stream only updates the tab that submitted. To push updates to **all** connected browsers, **broadcast** from the model over **Action Cable** (WebSockets). Rails 8 wires this up with almost no config.

`app/models/booking.rb` — add broadcast callbacks:
```ruby
class Booking < ApplicationRecord
  belongs_to :advisor
  delegate :agency, to: :advisor

  # Broadcast list changes to a per-agency stream
  after_create_commit  -> { broadcast_append_to agency, target: "bookings" }
  after_update_commit  -> { broadcast_replace_to agency }
  after_destroy_commit -> { broadcast_remove_to agency }

  # ... validations, business logic, scopes from Step 04 ...
end
```

Then **subscribe** the page to that stream. On the page that shows the list (e.g. the agency show or the bookings index), add:
```erb
<%= turbo_stream_from @agency %>   <%# subscribe this browser to @agency's stream %>
```

Now `broadcast_append_to agency, target: "bookings"` renders `_booking` server-side and pushes a `<turbo-stream action="append" target="bookings">` down the socket to **everyone subscribed to that agency** — open two tabs, create a booking in one, watch the other update.

- **`broadcast_*_to <stream>`** — which channel to push to (here, scoped per agency so hosts don't see each other's data).
- **`target:`** — the DOM id to act on (defaults to the model's `dom_id`, which is why `_booking` being wrapped in `turbo_frame_tag dom_id(booking)` from Step 05 makes `replace`/`remove` "just work").

> **Heads-up:** broadcasting fires from model callbacks, so the **total** won't auto-update via broadcast unless you also broadcast it. Add a callback that broadcasts a `replace` of `agency_<id>_total`, or keep totals on the request-response stream and broadcast only the list. Be deliberate — say *why* you chose one.

---

## Step 4 — Mirror it for update & destroy (request-response)

For completeness, add `format.turbo_stream` to `update` and `destroy` and the matching `update.turbo_stream.erb` / `destroy.turbo_stream.erb` (replace the row + replace the total; for destroy, `turbo_stream.remove @booking` + replace the total). The pattern is identical: **name an operation, name a target, hand it HTML.**

Commit:
```bash
git add -A && git commit -m "Turbo Streams: live booking list + roll-up totals, with broadcast"
```

---

## Frames vs. Streams (say this cleanly in the interview)

| | **Turbo Frame** | **Turbo Stream** |
|---|---|---|
| Updates | **One** region (the frame) | **Many** regions in one response |
| Operations | Replace the frame's contents | append / prepend / replace / update / remove / before / after |
| Who sees it | **Only the actor** | Actor (request-response) **or everyone** (broadcast) |
| Delivery | HTTP response | HTTP response **and/or** WebSocket broadcast |
| Best for | Inline edit, lazy-load a panel | Live lists, counters, notifications, multi-user dashboards |

---

## Things to look out for
- **The target id must exist on the page** when the stream arrives, or the action is silently dropped. Wrap targets (`#bookings`, `#agency_42_total`) deliberately.
- **`*_commit` callbacks, not `after_save`.** Broadcast `after_create_commit` / `after_update_commit` so you push **after the DB transaction commits** — otherwise you can broadcast data that then rolls back.
- **Broadcasting couples the model to the view.** It's convenient but it means a model "knows" about HTML. Fine for a small app; at scale some teams move broadcasts to a background job (`broadcast_*_later_to`) to keep requests fast. Mention you know the trade-off.
- **Scope your streams.** `turbo_stream_from @agency` (a per-record stream) keeps Agency A's updates out of Agency B's browser. A global `turbo_stream_from "bookings"` would leak across tenants.
- **Totals via broadcast need their own broadcast.** Streams only update the targets you explicitly push. Easy to forget the roll-up.
- **It still degrades gracefully.** If WebSockets fail, the `format.html` redirect path still works on the next load. HTML over the wire, not a hard SPA dependency.

## Check yourself
- [ ] Creating a booking appends a row **and** updates the total in one response (no reload).
- [ ] With two tabs open, creating a booking in one updates the list in the other (broadcast).
- [ ] Explain the 7 stream operations and that each needs a **target id**.
- [ ] Explain **request-response stream vs. broadcast stream** and when you'd use each.
- [ ] Explain why broadcasts use `after_*_commit`, not `after_save`.

## Interview talking points
- *"Turbo Streams let one server response update several parts of the page — I append the new booking row and re-render the agency's commission total in a single `create.turbo_stream.erb`, keeping the controller skinny."*
- *"For real-time, I broadcast from the model over Action Cable with `broadcast_append_to`, scoped per agency, and subscribe the page with `turbo_stream_from` — so a new booking updates every open dashboard with no JavaScript and no polling."*
- *"I think about the trade-off: broadcasting from model callbacks couples the model to the view and can be moved to a background job at scale, and I fire on `after_*_commit` so I never push uncommitted data."*

**Next:** `07-hotwire-stimulus.md` — add a **client-side live commission calculator** (type an amount and rate, see the commission update as you type) with a Stimulus controller.
