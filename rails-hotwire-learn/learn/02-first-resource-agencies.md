# Step 02 — Your First Resource: Agencies (CRUD + the "Rails Magic")

## Goal
Build complete **CRUD** (Create, Read, Update, Delete) for **Agencies** — the host agencies in our mini-Tern. You'll generate it with a scaffold, then **read every generated file** so you understand the magic instead of just running it. This single step covers migrations, Active Record, RESTful routes, controllers, strong params, ERB views, and validations.

## Why this matters
This is the moment Rails "clicks." One command produces a working, conventional CRUD feature. Interviewers love asking you to walk through what a scaffold generates because it touches the whole MVC stack. After this you'll genuinely understand it.

> Tern parallel: an Agency here is a **host agency** — the top of the commission hierarchy from `04-travel-industry-primer.md`.

---

## Step 1 — Generate the scaffold

In the WSL terminal, inside `commission_tracker`:

```bash
bin/rails generate scaffold Agency name:string iata_number:string default_commission_rate:decimal
```

`scaffold` generates a full vertical slice: model, migration, controller, views, routes, and tests. The `name:string` etc. declare columns and their types.

You'll see output listing created files. The key ones:
- `db/migrate/XXXX_create_agencies.rb` — the migration
- `app/models/agency.rb` — the model
- `app/controllers/agencies_controller.rb` — the controller
- `app/views/agencies/*` — the views
- `config/routes.rb` — gets `resources :agencies` added

---

## Step 2 — Run the migration

The scaffold wrote a migration but hasn't changed the database yet. Apply it:

```bash
bin/rails db:migrate
```

**What just happened:** Rails ran the migration, creating an `agencies` table, and updated `db/schema.rb`.

Open `db/migrate/XXXX_create_agencies.rb`:
```ruby
class CreateAgencies < ActiveRecord::Migration[8.0]
  def change
    create_table :agencies do |t|
      t.string :name
      t.string :iata_number
      t.decimal :default_commission_rate
      t.timestamps          # adds created_at + updated_at automatically
    end
  end
end
```
> **Migrations are versioned schema changes.** You never hand-edit `schema.rb`; you write migrations and run `db:migrate`. This is *exactly* the concept behind safely evolving a database during a client onboarding/data migration — a great thing to connect in the interview.

---

## Step 3 — See it work

```bash
bin/rails server
```
Visit **http://localhost:3000/agencies**. You have a working UI: list, create, show, edit, delete. Add a couple of agencies (e.g., "Wanderlust Collective", IATA "12345678", rate "0.15").

> Notice navigation feels instant — that's **Turbo Drive** (Hotwire) already working, no JS written. We'll go deep on Hotwire in Steps 05–07.

---

## Step 4 — Read the generated code (the important part)

### The model — `app/models/agency.rb`
```ruby
class Agency < ApplicationRecord
end
```
That's it — yet it has all of Active Record's power (querying, saving, validations). `ApplicationRecord` → `ActiveRecord::Base` gives it everything. The class name `Agency` maps by convention to the `agencies` table.

### The routes — `config/routes.rb`
```ruby
resources :agencies
```
This **one line** creates all seven RESTful routes:

| HTTP verb | Path | Controller#action | Purpose |
|---|---|---|---|
| GET | /agencies | agencies#index | list all |
| GET | /agencies/new | agencies#new | form for a new one |
| POST | /agencies | agencies#create | save the new one |
| GET | /agencies/:id | agencies#show | show one |
| GET | /agencies/:id/edit | agencies#edit | form to edit |
| PATCH/PUT | /agencies/:id | agencies#update | save edits |
| DELETE | /agencies/:id | agencies#destroy | delete |

> **REST** = mapping HTTP verbs + URLs to these standard actions. Run `bin/rails routes` to see them all. This convention is core Rails fluency.

### The controller — `app/controllers/agencies_controller.rb`
Read it. Key patterns:
```ruby
def index
  @agencies = Agency.all          # instance var → available in the view
end

def show
  # @agency set by the before_action below
end

def create
  @agency = Agency.new(agency_params)
  if @agency.save
    redirect_to @agency, notice: "Agency was successfully created."
  else
    render :new, status: :unprocessable_entity
  end
end

private

# "strong parameters" — a security allowlist of permitted fields
def agency_params
  params.require(:agency).permit(:name, :iata_number, :default_commission_rate)
end
```
Two things to understand and be able to explain:
- **Strong parameters** (`params.require(...).permit(...)`): you must explicitly allowlist which form fields can be saved. Prevents mass-assignment attacks. **Common interview question.**
- The **`create` pattern**: try to save; on success **redirect**, on failure **re-render the form** with a 422 status (so Turbo shows the validation errors). This save-or-re-render pattern is everywhere in Rails.

### The views — `app/views/agencies/`
- `index.html.erb` — the list
- `show.html.erb` — one agency
- `new.html.erb` / `edit.html.erb` — both render the shared `_form.html.erb` **partial**
- `_agency.html.erb` — a **partial** for rendering a single agency (reused in the list and show)

ERB basics:
- `<%= ... %>` outputs the result into the HTML (e.g., `<%= @agency.name %>`)
- `<% ... %>` runs Ruby without outputting (e.g., loops, `if`)
- **Partials** are reusable view fragments; filenames start with `_`. `render @agencies` automatically renders the `_agency` partial for each item — another convention.

---

## Step 5 — Add validations (make the model enforce rules)

Edit `app/models/agency.rb`:
```ruby
class Agency < ApplicationRecord
  validates :name, presence: true
  validates :default_commission_rate,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 },
            allow_nil: true
end
```
Now try to create an agency with no name in the browser → it re-renders the form with an error. Try it in the console too:
```bash
bin/rails console
```
```ruby
a = Agency.new(name: "")
a.valid?          # => false
a.errors.full_messages   # => ["Name can't be blank"]
a.save            # => false (won't persist)
exit
```
> **Validations protect data integrity** — directly relevant to onboarding/migrating client data cleanly (no nameless agencies, rates in a sane range). Mention this connection.

Commit:
```bash
git add -A && git commit -m "Agencies CRUD with validations"
```

---

## Things to look out for
- **Run `db:migrate` after generating** anything with a migration, or the table won't exist (you'll get "no such table" / `PendingMigrationError`).
- **Decimal for money/rates, never float.** Floats cause rounding errors — fatal for commissions. We used `decimal` deliberately; remember this reasoning.
- **Strong params** must list every field you want saved; forget one and it silently won't save.
- **Pluralization:** `Agency` → `agencies` (Rails handles irregular plurals via its inflector). If you ever see weird table names, that's why.
- Scaffolding is great for *learning* and admin CRUD; in real apps you often generate a `model` or `controller` separately rather than full scaffolds. Know that nuance.

## Check yourself
- [ ] Create, edit, and delete an agency in the browser.
- [ ] Run `bin/rails routes` and find the 7 agency routes.
- [ ] Explain strong parameters and why they exist.
- [ ] Explain what a migration is and why you don't edit `schema.rb` directly.
- [ ] In the console, create an invalid agency and read `errors.full_messages`.

## Interview talking points
- *"`resources :agencies` generates the seven RESTful routes; the controller actions map to them, and views render via ERB and partials."*
- *"Strong parameters are Rails' allowlist against mass-assignment — you explicitly permit the fields a form can set."*
- *"Schema changes go through versioned migrations, not hand-editing — which is the same discipline you want when migrating a client's data during onboarding."*
- *"I used `decimal`, not `float`, for commission rates and amounts to avoid floating-point rounding — money correctness matters in this domain."*

**Next:** `03-associations-advisors.md` — add Advisors that `belong_to` an Agency, and learn Active Record associations (the heart of the data model).
