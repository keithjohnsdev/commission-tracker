# Step 01 — Rails Fundamentals & Project Tour

## Goal
Before building features, understand **how a Rails app is organized** and **how a web request flows through it**. No code changes here — this is the mental model that makes everything after it click (and that interviewers probe for).

## Why this matters
Rails is **"convention over configuration"** — it has strong opinions about where things go and how they're named. Once you know the conventions, the framework does a huge amount for you. Interviewers don't want trivia; they want to hear that you understand **MVC** and the **request lifecycle**. That's this doc.

---

## The big idea: Convention over Configuration (CoC) + MVC

- **CoC:** follow Rails' naming/structure conventions and it wires things up automatically — far less boilerplate. "Opinionated" = the happy path is to do it Rails' way.
- **MVC (Model–View–Controller):** how a Rails app separates concerns.

```
Browser request:  GET /agencies/5
        │
        ▼
   ROUTER (config/routes.rb)         "which controller action handles this URL?"
        │   → AgenciesController#show, with params[:id] = 5
        ▼
   CONTROLLER (app/controllers)      orchestrates: asks the model for data
        │   @agency = Agency.find(5)
        ▼
   MODEL (app/models)                Active Record: talks to the database
        │   ← returns the Agency record
        ▼
   VIEW (app/views)                  renders HTML (ERB) using @agency
        │
        ▼
   HTML response → browser
```

- **Model** — a Ruby class mapped to a DB table (via **Active Record**). Holds data, relationships, validations, business logic. e.g. `Agency`, `Advisor`, `Booking`.
- **View** — templates (`.html.erb`) that produce the HTML the user sees.
- **Controller** — the traffic cop: receives the request, calls models, picks the view/response.
- **Router** — maps URL + HTTP verb → a controller action.

> One-line version to memorize: *"A request hits the router, which routes it to a controller action, which uses Active Record models to get data, then renders a view back as HTML."*

---

## Tour the project (open `~/Desktop/tern/commission_tracker` in your editor)

The folders that matter (ignore the rest for now):

```
app/
  controllers/     ← your controllers (request handling)
  models/          ← your Active Record models (data + logic)
  views/           ← your ERB templates (HTML)
  javascript/      ← Stimulus controllers live here (Hotwire)
  assets/          ← CSS, images (Propshaft pipeline)
config/
  routes.rb        ← URL → controller mapping (you'll edit this a lot)
  database.yml     ← DB config (SQLite for us)
db/
  migrate/         ← migration files (schema changes over time)
  schema.rb        ← the current DB schema (auto-generated; don't hand-edit)
  seeds.rb         ← sample data you can load
Gemfile            ← your gems (libraries); like package.json
bin/
  rails            ← the command you run for almost everything
test/              ← Minitest tests (Rails' default test framework)
```

Coming from Node/React, the mental mapping:
- `Gemfile` ≈ `package.json`; **Bundler** ≈ npm/yarn; `bundle install` ≈ `npm install`.
- `bin/rails` ≈ your CLI (`rails generate`, `rails db:migrate`, `rails console`, `rails server`).
- Active Record ≈ an ORM like Prisma/TypeORM, but more "magic" and convention-driven.
- ERB views ≈ server-rendered templates (think the opposite of a client-side React SPA — Rails renders HTML on the server; Hotwire keeps it feeling live).

---

## Two tools you'll use constantly

**1. The server**
```bash
bin/rails server     # or: bin/rails s
```
Runs the app at `localhost:3000`. Leave it running in one terminal; it auto-reloads code changes.

**2. The console** (this is a superpower — and a great interview mention)
```bash
bin/rails console    # or: bin/rails c
```
A live REPL **inside your app** with full access to your models and data:
```ruby
Agency.count               # how many agencies?
Agency.all                 # every agency
a = Agency.new(name: "Wanderlust")   # build one in memory
a.save                     # persist it
Agency.find_by(name: "Wanderlust")   # query it back
exit
```
> Ops/support engineers (the kind of onboarding role you're targeting) live in the console to inspect and fix data. Being comfortable here is directly relevant.

---

## The request lifecycle, concretely (you'll see this in Step 02)
1. You define a route in `config/routes.rb`.
2. A controller action handles it and sets instance variables (`@agency`).
3. Rails renders the matching view (`app/views/agencies/show.html.erb`) — instance variables from the controller are available in the view.
4. The HTML goes back to the browser. With Hotwire's **Turbo Drive** on by default, navigation feels SPA-fast without you writing JS.

---

## Things to look out for
- **Naming conventions are load-bearing.** Model `Agency` (singular, CamelCase) ↔ table `agencies` (plural, snake_case) ↔ controller `AgenciesController` ↔ views in `app/views/agencies/`. Rails infers connections from these names — break the convention and the "magic" stops.
- **`schema.rb` is generated**, not hand-edited. You change the schema via **migrations** (Step 02).
- **Instance variables (`@agency`) are the bridge** from controller to view. Regular variables aren't shared across that boundary.
- Don't memorize the whole folder tree — memorize **MVC + the request flow**. That's what gets asked.

## Check yourself (no code, just explain)
- [ ] Draw the request flow: router → controller → model → view → HTML.
- [ ] Define Model, View, Controller in one sentence each.
- [ ] What's the difference between `bin/rails server` and `bin/rails console`?
- [ ] What does "convention over configuration" mean, with one example (e.g., `Agency` → `agencies` table)?

## Interview talking points
- *"Rails is MVC with convention over configuration — a request goes router → controller → Active Record model → view, and the conventions mean I write far less wiring code."*
- *"Coming from the JS world, Active Record is like an ORM but more opinionated, and ERB is server-rendered HTML — which pairs with Hotwire so the app feels live without a separate React frontend."*
- *"I lean on `rails console` to inspect and manipulate data directly — useful for the kind of data-migration and onboarding work this role involves."*

**Next:** `02-first-resource-agencies.md` — build full CRUD for Agencies and watch the conventions do the heavy lifting.
