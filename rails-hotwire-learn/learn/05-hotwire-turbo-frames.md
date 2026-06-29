# Step 05 — Hotwire I: Turbo Frames (inline-edit a booking, no reload)

## Goal
Make a single booking **editable in place** — click "Edit," the row turns into a form, save, and it swaps back — **without a full page reload and without writing any JavaScript**. This is your first real Hotwire feature and the cleanest way to *show* (not just claim) that you understand Tern's frontend stack.

## Why this matters
Hotwire is the headline of Tern's stack and the thing that differentiates them from "just another Rails shop." The pitch is **"HTML over the wire"**: instead of shipping JSON to a React SPA and re-rendering in the browser, the server sends **rendered HTML fragments** and Turbo swaps them in. Turbo Frames are the simplest piece — *"scope a part of the page so links and forms only update that part."* Being able to explain the philosophy **and** point at a thing you built is the whole game.

> Tern parallel: a host's booking grid where an advisor tweaks a commission rate inline — the row updates, the rest of the page (totals, nav, other rows) stays put. That's a Turbo Frame.

---

## Step 0 — Understand what's *already* happening: Turbo Drive

You haven't touched JavaScript, but your app is **already a single-page-ish app**. Rails 8 ships **Turbo Drive** on by default (the `turbo-rails` gem, loaded in `app/javascript/application.js`).

Turbo Drive intercepts every link click and form submit, fetches the new page with `fetch()`, and **swaps the `<body>`** instead of doing a full browser reload — keeping the `<head>`, CSS, and JS in memory. That's why navigating between agencies feels instant.

> Say this in the interview: *"Turbo Drive turns a plain Rails app into an SPA-like experience for free — no full reloads — and Turbo Frames and Streams let me get more surgical from there."*

Two things to know:
- **It's automatic.** No code. You can opt a link out with `data-turbo="false"`.
- **Form redirects still work normally** — Turbo follows the redirect and swaps the body.

---

## Step 1 — Wrap each booking in a Turbo Frame

A **Turbo Frame** is a `<turbo-frame id="...">` element. The rule: **a link or form *inside* a frame only replaces *that frame*** — Turbo finds the matching frame (same `id`) in the server's HTML response and swaps just that piece.

Rails 8's scaffold already rendered a partial for one booking at `app/views/bookings/_booking.html.erb`. Wrap its contents in a frame keyed to the record:

```erb
<%= turbo_frame_tag dom_id(booking) do %>
  <div class="booking">
    <p><strong><%= booking.trip_name %></strong> — <%= booking.supplier_name %></p>
    <p>Amount: <%= number_to_currency(booking.total_amount) %></p>
    <p>Expected commission: <%= number_to_currency(booking.expected_commission) %></p>

    <%= link_to "Edit", edit_booking_path(booking) %>
  </div>
<% end %>
```

- **`turbo_frame_tag dom_id(booking)`** renders `<turbo-frame id="booking_42">…</turbo-frame>`.
- **`dom_id(booking)`** is a Rails helper that returns a stable, unique id like `"booking_42"` — use it everywhere so frames, streams, and DOM ids all agree.
- The **`Edit` link is *inside* the frame**, so clicking it loads its response *into this frame* — not the whole page.

---

## Step 2 — Make the edit view answer with a matching frame

When you click "Edit," Turbo fetches `edit_booking_path(booking)` and looks for a `<turbo-frame id="booking_42">` in the response. If it finds one, it swaps **only that frame's contents** in. So the edit page must wrap its form in the **same frame id**.

`app/views/bookings/edit.html.erb`:
```erb
<h1>Editing booking</h1>

<%= turbo_frame_tag dom_id(@booking) do %>
  <%= render "form", booking: @booking %>
  <%= link_to "Cancel", booking_path(@booking) %>
<% end %>
```

That's the whole trick:
- **Read view** (`_booking`) and **edit view** share `turbo_frame_tag dom_id(@booking)`.
- Click Edit → Turbo pulls the *form's* frame and drops it where the *read* frame was. The row becomes a form **in place**.

---

## Step 3 — Close the loop: save swaps it back

The scaffold's `update` action already does the right thing:

```ruby
# app/controllers/bookings_controller.rb (generated)
def update
  if @booking.update(booking_params)
    redirect_to @booking, notice: "Booking was successfully updated."
  else
    render :edit, status: :unprocessable_entity
  end
end
```

On success it **redirects to the show page**. Turbo follows the redirect, finds `<turbo-frame id="booking_42">` on that page (because `show.html.erb` does `render @booking`), and swaps the **read view** back into the frame. Form → saved row, no reload.

Make sure `app/views/bookings/show.html.erb` renders the partial:
```erb
<%= render @booking %>
<%= link_to "Back to bookings", bookings_path %>
```

**Try it:** go to `/bookings`, click Edit on one row. It becomes a form. Change the rate, Save. The row updates in place — the rest of the page never flickered.

---

## Step 4 — A note on the validation-error path

When `update` fails validation it does `render :edit, status: :unprocessable_entity`. Because the response *still contains the matching frame* (the edit form with error messages), Turbo swaps the errored form back into the frame. **Inline editing keeps working even on errors** — that `unprocessable_entity` (422) status is what tells Turbo to render the body of a failed form submission. Don't remove it.

Commit:
```bash
git add -A && git commit -m "Turbo Frames: inline-edit a booking with no reload"
```

---

## How to think about Turbo Frames (the mental model)

```
Page
 ├─ nav / totals / other rows  ← untouched
 └─ <turbo-frame id="booking_42">
        clicking a link/form INSIDE this frame
        → Turbo fetches the URL
        → finds <turbo-frame id="booking_42"> in the response
        → swaps ONLY this frame's contents
```
- A frame is a **self-contained, independently-updatable region** of the page.
- The contract is the **matching `id`**. Same id on both the trigger's page and the response's page = swap. No match = Turbo errors (you'll see "content missing" — that's your tell).
- **Zero JavaScript.** It's HTML attributes (`<turbo-frame>`) plus a server that renders the right fragment.

---

## Things to look out for
- **Frame ids must match.** If Edit does nothing or you see "Content missing," the response's frame id ≠ the trigger's frame id. `dom_id(@booking)` on both sides keeps them in sync.
- **Links/forms must be *inside* the frame** to target it automatically. To drive a frame from *outside* it, add `data-turbo-frame="booking_42"` to the link.
- **Keep the 422 status** on validation failure (`status: :unprocessable_entity`) — without it Turbo won't render the errored form back into the frame.
- **Lazy-loading frames** are a related trick: `<turbo-frame id="x" src="/path">` fetches its content on load (great for deferring slow panels). Know it exists.
- **Frames replace, they don't broadcast.** A frame only updates *for the person who clicked*. To push updates to *other* users/tabs, you need **Turbo Streams** (next step).

## Check yourself
- [ ] Clicking "Edit" turns one booking into a form **in place**, no full reload.
- [ ] Saving swaps the read view back into the same frame.
- [ ] Explain the **matching-`id` contract** between the frame on the trigger page and the frame in the response.
- [ ] Explain the difference between **Turbo Drive** (whole-body swap, automatic) and a **Turbo Frame** (scoped swap).
- [ ] Explain why `dom_id(booking)` is the right way to key a frame.

## Interview talking points
- *"Turbo Drive already gives a Rails app SPA-like navigation for free — it swaps the body instead of full reloads. Turbo Frames let me get surgical: I scope a region with `turbo_frame_tag` and links/forms inside it only replace that region."*
- *"I built inline editing of a booking with zero JavaScript — the read partial and the edit form share a frame id, so Turbo swaps the form in on Edit and swaps the saved row back on redirect."*
- *"The whole contract is a matching frame `id` between the trigger page and the response, which is why I key frames with `dom_id`. It's HTML over the wire — the server stays in charge of rendering."*

**Next:** `06-hotwire-turbo-streams.md` — push **live updates to lists and roll-up totals** when bookings change, both as a form response and **broadcast** to every open tab.
