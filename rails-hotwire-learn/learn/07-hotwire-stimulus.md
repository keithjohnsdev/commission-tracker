# Step 07 — Hotwire III: Stimulus (a live commission calculator)

## Goal
Add a small **client-side** behavior with **no server round-trip**: in the booking form, as you type a **total amount** and a **commission rate**, a live preview shows the **expected commission** updating on every keystroke. This is the third leg of Hotwire and the place to show you know **when to reach for JavaScript and when not to**.

## Why this matters
Turbo (Frames + Streams) handles **server-driven** HTML. But some interactions are purely **in the browser** — live previews, toggles, dropdowns, copy-to-clipboard — where a server round-trip would be silly. **Stimulus** is Hotwire's answer: a tiny, convention-driven JavaScript framework that attaches behavior to existing HTML via `data-` attributes. The senior insight isn't "I can write JS" — it's *"I reach for Stimulus for sprinkles of interactivity and let Turbo own the data, instead of dragging in React for everything."* That's exactly the philosophy Tern's stack is built on.

> Tern parallel: an advisor entering a booking sees the commission they'll earn **before** saving — instant feedback, computed in the browser, no request. (The server still computes the authoritative value on save — Step 04.)

---

## Step 1 — Generate a Stimulus controller

Rails 8 ships Stimulus via the `stimulus-rails` gem + importmap. Controllers live in `app/javascript/controllers/` and **auto-register** (the generated `controllers/index.js` eager-loads everything in that folder — no manual wiring).

```bash
bin/rails generate stimulus commission_calculator
```

That creates `app/javascript/controllers/commission_calculator_controller.js`:
```js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
  }
}
```

---

## Step 2 — Learn the three core concepts (targets, actions, values)

Stimulus connects HTML to a controller through `data-` attributes. There are three you'll use constantly:

- **Controller** — `data-controller="commission-calculator"` marks the region the controller manages (its "scope"). Note the **kebab-case** name maps to the `commission_calculator` file.
- **Targets** — `data-commission-calculator-target="amount"` marks an element the controller wants a handle on. In JS you get `this.amountTarget` (and `this.amountTargets`, `this.hasAmountTarget`).
- **Actions** — `data-action="input->commission-calculator#calculate"` wires a **DOM event** (`input`) to a **controller method** (`calculate`).

(There's a fourth, **values** — typed, reactive data passed from HTML like `data-commission-calculator-default-rate-value="0.15"` — we'll use it for the agency's fallback rate.)

---

## Step 3 — Write the controller

Replace the generated file with:
```js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="commission-calculator"
export default class extends Controller {
  static targets = ["amount", "rate", "output"]
  static values  = { defaultRate: Number }

  connect() {
    this.calculate()   // show a value immediately on page load
  }

  calculate() {
    const amount = parseFloat(this.amountTarget.value) || 0
    const rate   = parseFloat(this.rateTarget.value) || this.defaultRateValue || 0
    const commission = amount * rate

    this.outputTarget.textContent = commission.toLocaleString("en-US", {
      style: "currency", currency: "USD"
    })
  }
}
```

- **`static targets`** declares the handles → gives you `this.amountTarget`, `this.rateTarget`, `this.outputTarget`.
- **`static values = { defaultRate: Number }`** declares a typed value → `this.defaultRateValue` (auto-coerced to a Number).
- **`connect()`** runs whenever the controller's element appears in the DOM — including **after a Turbo navigation or stream**, which is exactly why Stimulus and Turbo pair well: behavior re-attaches automatically to swapped-in HTML.

---

## Step 4 — Wire the HTML in the booking form

In `app/views/bookings/_form.html.erb`, your amount and rate fields are currently plain `text_field`s:
```erb
<div>
  <%= form.label :total_amount, style: "display: block" %>
  <%= form.text_field :total_amount %>
</div>

<div>
  <%= form.label :commission_rate, style: "display: block" %>
  <%= form.text_field :commission_rate %>
</div>
```
Replace **those two `<div>`s** with a single region wrapped in the controller — switch the inputs to `number_field` (so `step: :any` allows decimals) and add the target/action data attributes plus a live output:
```erb
<div data-controller="commission-calculator"
     data-commission-calculator-default-rate-value="<%= Agency.first&.default_commission_rate || 0 %>">

  <div>
    <%= form.label :total_amount, style: "display: block" %>
    <%= form.number_field :total_amount, step: :any,
          data: { commission_calculator_target: "amount",
                  action: "input->commission-calculator#calculate" } %>
  </div>

  <div>
    <%= form.label :commission_rate, "Commission rate (e.g. 0.15)", style: "display: block" %>
    <%= form.number_field :commission_rate, step: :any,
          data: { commission_calculator_target: "rate",
                  action: "input->commission-calculator#calculate" } %>
  </div>

  <p>
    Estimated commission:
    <strong data-commission-calculator-target="output">$0.00</strong>
  </p>
</div>
```

**Try it:** open `/bookings/new`, type `8000` and `0.16` → the preview reads **$1,280.00**, updating on every keystroke. Clear the rate → it falls back to the agency default value. No network requests (watch the Network tab — nothing fires).

> **Honest caveat on `Agency.first`:** your booking form picks an **advisor** (via `collection_select`), and the real default rate belongs to *that advisor's* agency — which the browser can't know until an advisor is chosen. `Agency.first&.default_commission_rate` is a **demo stand-in** that works because you have one agency. To make the fallback truly correct you'd refresh the value when the advisor changes (a `defaultRateValueChanged()` callback driven by a second action on the advisor `<select>`, or a tiny fetch). Fine to leave for the exercise — just know *why* it's a stand-in.

> **Stimulus is already wired** in your repo: `config/importmap.rb` pins `@hotwired/stimulus` and `pin_all_from "app/javascript/controllers"`, and there's a sample `hello_controller.js`. The generator just drops in your new file — no manual registration.

Commit:
```bash
git add -A && git commit -m "Stimulus: live client-side commission calculator"
```

---

## How to think about Stimulus (the mental model)

```
HTML is the source of truth. Stimulus attaches behavior to it.

<div data-controller="commission-calculator">      ← scope
  <input data-…-target="amount"                     ← a handle
         data-action="input->…#calculate">          ← event → method
  <strong data-…-target="output">                   ← a handle
</div>

controller.js:  this.amountTarget, this.outputTarget, calculate()
```
- Stimulus **doesn't render HTML** and **doesn't own state** — Rails/Turbo render the HTML; Stimulus just adds behavior. This is the opposite of React, where the component owns the DOM.
- Controllers are **small, reusable, and stateless-ish** — `commission-calculator` could live on any form with those targets.
- It's **resilient to Turbo**: because behavior is declared in `data-` attributes on the HTML, swapped-in fragments (frames/streams) get their controllers connected automatically.

---

## Things to look out for
- **Naming maps by convention.** File `commission_calculator_controller.js` → `data-controller="commission-calculator"`; target attr is `data-commission-calculator-target="amount"`. A mismatch = silently nothing. (Check the browser console — Stimulus warns.)
- **`connect()` can run more than once** as elements are added/removed by Turbo. Keep it idempotent; use `disconnect()` to tear down timers/listeners you set up.
- **Client preview is *not* authoritative.** Always recompute on the server at save time (Step 04's `expected_commission`). The browser value is UX; the model value is truth. Be explicit about this — it's a correctness point.
- **Use `values`, not hardcoded constants,** to pass server data in (`defaultRateValue`). Values are typed and reactive (you can add a `defaultRateValueChanged()` callback).
- **Don't reach for Stimulus when Turbo will do.** If the update needs server data or must persist, it's a Turbo Frame/Stream, not Stimulus. Knowing the boundary is the point.

## Check yourself
- [ ] Typing amount + rate updates the preview live with **no network request**.
- [ ] Clearing the rate falls back to the agency default via a Stimulus **value**.
- [ ] Explain **controller / target / action / value** in one sentence each.
- [ ] Explain why Stimulus pairs well with Turbo (behavior re-attaches to swapped-in HTML).
- [ ] Explain why the client number is *not* the source of truth.

## Interview talking points
- *"Stimulus is for sprinkles of client-side behavior — I built a live commission preview that computes on every keystroke with no round-trip, using targets for the inputs/output and an action to bind the `input` event."*
- *"It attaches behavior to server-rendered HTML via `data-` attributes instead of owning the DOM like React, so it re-connects automatically to fragments Turbo swaps in — that's why the Hotwire trio composes so well."*
- *"I'm deliberate about the boundary: anything that needs server data or has to persist is a Turbo Frame or Stream; only pure in-browser UX is Stimulus. And the client value is never authoritative — the model recomputes commission on save."*

**Next:** `08-dashboard-and-reconciliation.md` — build an agency **dashboard** with roll-ups and a **"commission received" toggle** that flips state and updates live via Turbo Stream.
