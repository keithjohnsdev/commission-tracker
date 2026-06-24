# Rails + Hotwire Learning Project — "Commission Tracker" (mini-Tern)

A guided, step-by-step build to get Keith **confident discussing Ruby on Rails and Hotwire in interview conversation** — using an app that mirrors **Tern's actual domain** (agencies, advisors, bookings, commissions). By the end you'll be able to say, truthfully: *"I built and deployed a small Rails + Hotwire app that models exactly this — host agencies, advisors, bookings, and multi-layer commission splits."*

> Stack target: **Ruby 3.3.x + Rails 8 + Hotwire (Turbo + Stimulus) + SQLite** (with a documented note on Postgres, which Tern uses). Dev environment: **macOS** (native Unix — no WSL needed; the natural Rails setup).

---

## What we're building

**Commission Tracker** — a back-office tool where a host agency tracks the bookings its advisors make and the commission owed/received. It's intentionally small but models the real relationships:

```
Agency (the host)
  └─ has many Advisors
        └─ each Advisor has many Bookings
              └─ each Booking has a supplier, trip, amount, commission rate
                 → computes expected commission
                 → can be marked "commission received" (reconciliation)
Agency totals roll up from all its bookings (live, via Hotwire).
```

**Features you'll build (each teaches something):**
1. CRUD for Agencies — the "Rails magic" intro (scaffolding, MVC, migrations, REST).
2. Advisors that **belong to** an agency — associations + forms with dropdowns.
3. Bookings with a **computed expected commission** — a 3rd model, `has_many :through`, business logic in the model, money handling.
4. **Inline editing** of a booking without a page reload — **Turbo Frames**.
5. **Live-updating agency commission totals** when bookings change — **Turbo Streams**.
6. A **live commission calculator** (type an amount + rate, see commission update instantly) — **Stimulus**.
7. A **dashboard** with roll-ups + a **"commission received" toggle** — reconciliation flavor.
8. **Tests + deploy** + an interview talking-points cheat sheet.

Why this app: it forces you through *every* core concept, and every feature has a one-line Tern parallel you can mention in the interview.

---

## The plan (steps → learning docs)

Each step has a doc in `learn/`. Read the doc, do the step, then read its **Interview talking points** section out loud.

| # | Doc | You'll build | Core concepts |
|---|---|---|---|
| 00 | `learn/00-environment-setup.md` | macOS + Ruby + Rails installed; empty app runs | Homebrew, rbenv, `rails new`, `bin/rails server`, SQLite vs Postgres |
| 01 | `learn/01-rails-fundamentals.md` | A tour of what got generated; understand the request lifecycle | MVC, project structure, `rails console`, the request→response cycle |
| 02 | `learn/02-first-resource-agencies.md` | Full CRUD for Agencies | scaffolding, migrations, Active Record, RESTful routes, controllers, ERB views, strong params, validations |
| 03 | `learn/03-associations-advisors.md` | Advisors belonging to Agencies | `belongs_to` / `has_many`, foreign keys, nested forms, `collection_select` |
| 04 | `learn/04-bookings-and-business-logic.md` | Bookings + computed commission | a 3rd model, `has_many :through`, model methods, money/decimals, validations |
| 05 | `learn/05-hotwire-turbo-frames.md` | Inline edit a booking, no reload | Turbo Drive (what's already happening), **Turbo Frames** |
| 06 | `learn/06-hotwire-turbo-streams.md` | Live-updating totals & lists | **Turbo Streams**, `turbo_stream` responses, broadcasting |
| 07 | `learn/07-hotwire-stimulus.md` | Live commission calculator | **Stimulus** controllers, targets, actions, values |
| 08 | `learn/08-dashboard-and-reconciliation.md` | Dashboard + "received" toggle | roll-ups, scopes, partials, a reconciliation toggle via Turbo Stream |
| 09 | `learn/09-tests-deploy-talking-points.md` | Tests, deploy, and your interview script | Minitest basics, deploy (Render/Fly), full talking-points map |

*(Docs 00–02 are written now; 03–09 will follow once you've confirmed the format.)*

---

## Concept coverage map (so you can see the interview surface area)

**Ruby/Rails:** MVC · convention over configuration · Active Record (ORM) · migrations · associations (`belongs_to`, `has_many`, `has_many :through`) · validations · RESTful routing · controllers + strong params · ERB views + partials · model business logic · scopes · `rails console` · gems/Bundler · the asset pipeline (Propshaft) · importmaps.

**Hotwire:** Turbo Drive · Turbo Frames · Turbo Streams (request-response **and** broadcast) · Stimulus (controllers/targets/actions/values) · the "HTML over the wire" philosophy vs. a React SPA.

**Pro/Tern context:** SQLite vs Postgres · how this maps to Tern's stack · multi-layer commission splits · why a Rails + Hotwire monolith suits a lean, ship-weekly team.

---

## How to use these docs

1. **Read the doc top to bottom first**, then do the steps — don't just copy-paste. Understanding > completion.
2. **You're an AI-native dev — use it.** Build this *with* Claude Code in the project (it's literally Tern's workflow). But for each concept, make sure you can *explain it without the AI* — that's the interview test. Each doc ends with talking points for exactly that.
3. **Say the "Interview talking points" out loud** at the end of each step. Repetition is how "I read about Turbo Frames" becomes "I used Turbo Frames to do inline editing."
4. **Commit after each step** (`git commit`) — you'll have a clean history to show, and it's good practice.

## Where the app lives (read in doc 00)
Recommendation: generate the Rails app at **`~/Desktop/tern/commission_tracker`** on your Mac (next to the `tern-prep` repo) and keep it as its own repo. The **learning docs live in the `tern-prep` repo**. On macOS there's no filesystem-bridge slowness (unlike Windows/WSL `/mnt/c`), so location is about organization, not speed. Doc 00 covers the details.

## Definition of done
- App deployed to a public URL (portfolio asset — ties to your `career/job-search-plan.md` "build a portfolio" action).
- You can explain MVC, Active Record associations, and all three Hotwire pieces in plain English, each with a concrete thing you built.
- You can draw the Agency→Advisor→Booking→Commission model and relate it to Tern.
