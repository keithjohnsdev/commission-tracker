# Step 03 — Associations: Advisors belong to Agencies

## Goal
Add an **Advisor** model where each advisor **belongs to** an agency, and each agency **has many** advisors. This teaches **Active Record associations** — the single most important Rails concept for understanding a data model (and the thing to nail when discussing Tern's commission hierarchy).

## Why this matters
Associations are how Rails models relationships between tables in plain English. Tern's whole domain is relationships: a host **has many** advisors; an advisor **has many** bookings; commissions **roll up** through that hierarchy. If you can talk about `belongs_to` / `has_many` fluently and relate it to that hierarchy, you sound like someone who already gets their data model.

> Tern parallel: Agency = host agency, Advisor = an IC (independent contractor) booking under that host (`04-travel-industry-primer.md`).

---

## Step 1 — Generate the Advisor scaffold with a reference

```bash
bin/rails generate scaffold Advisor name:string email:string agency:references
bin/rails db:migrate
```

The magic word is **`agency:references`**. Open the generated migration:
```ruby
class CreateAdvisors < ActiveRecord::Migration[8.0]
  def change
    create_table :advisors do |t|
      t.string :name
      t.string :email
      t.references :agency, null: false, foreign_key: true   # ← the relationship
      t.timestamps
    end
  end
end
```
`t.references :agency` does three things:
1. Adds an **`agency_id`** column (the **foreign key**).
2. Adds a **database index** on it (fast lookups).
3. `foreign_key: true` adds a **DB-level constraint** so an advisor can't point to a non-existent agency.

It also auto-adds `belongs_to :agency` to the model.

---

## Step 2 — Wire up both sides of the association

`references` gave you the `belongs_to` side. You add the `has_many` side manually.

`app/models/advisor.rb`:
```ruby
class Advisor < ApplicationRecord
  belongs_to :agency          # added by the generator

  validates :name, presence: true
  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
end
```

`app/models/agency.rb` — add the other side:
```ruby
class Agency < ApplicationRecord
  has_many :advisors, dependent: :destroy   # ← add this

  validates :name, presence: true
  validates :default_commission_rate,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 },
            allow_nil: true
end
```

**What this gives you** (try it in `bin/rails console`):
```ruby
agency  = Agency.first
agency.advisors            # => all advisors for this agency
agency.advisors.create(name: "Jordan Lee", email: "jordan@example.com")
agency.advisors.count

advisor = Advisor.first
advisor.agency             # => the parent agency
advisor.agency.name
```
> The association methods (`agency.advisors`, `advisor.agency`) are generated **from the association declarations** — convention over configuration again.

**`dependent: :destroy`** means: if you delete an agency, its advisors are deleted too (no orphaned records). Without it you'd leave advisors pointing at a deleted agency. Choosing the right `dependent:` option is a real data-integrity decision — relevant to onboarding/migrations.

---

## Step 3 — Make the form pick an agency by name (not a raw ID)

The scaffold's `_form` for Advisor likely renders a plain number field for `agency_id`. Make it a dropdown.

Open `app/views/advisors/_form.html.erb` and replace the `agency_id` field with:
```erb
<div>
  <%= form.label :agency_id, "Agency" %>
  <%= form.collection_select :agency_id, Agency.order(:name), :id, :name,
        { prompt: "Select an agency" } %>
</div>
```
`collection_select(field, collection, value_method, text_method, options)`:
- `Agency.order(:name)` — the options, alphabetized
- `:id` — what gets submitted (the value)
- `:name` — what the user sees (the label)

Now `/advisors/new` shows a real dropdown. Create a couple of advisors under your agency.

---

## Step 4 — Show an agency's advisors on its page

Open `app/views/agencies/show.html.erb` and add (near the bottom, before any "Edit/Back" links):
```erb
<h2>Advisors</h2>
<ul>
  <% @agency.advisors.each do |advisor| %>
    <li><%= link_to advisor.name, advisor %> — <%= advisor.email %></li>
  <% end %>
</ul>
<%= link_to "Add advisor", new_advisor_path %>
```
Visit an agency's show page → you see its advisors. You're now navigating the association in a view.

Commit:
```bash
git add -A && git commit -m "Advisors belong to Agencies (associations)"
```

---

## How to think about associations (the mental model)

```
Agency  ──has_many──▶  Advisor
   ▲                      │
   └──────belongs_to──────┘

DB:   agencies            advisors
      id, name, ...       id, name, email, agency_id  ← FK points "up"
```
- The **`belongs_to`** side holds the **foreign key** (`advisors.agency_id`).
- The **`has_many`** side has **no column** — Rails infers it by looking for `agency_id` on advisors.
- Both declarations are needed to get the convenience methods on both sides.

Other association types you should be able to name (you'll use `has_many :through` in Step 04):
- `has_one` — one-to-one (e.g., a user has one profile)
- `has_many :through` — many-to-many or "reach across" a join (Agency → Bookings *through* Advisors)
- `has_and_belongs_to_many` — simpler many-to-many without a join model (less common now)

---

## Things to look out for
- **`belongs_to` is required by default** (Rails 5+). An advisor with no agency fails validation. To allow a null parent: `belongs_to :agency, optional: true`. (Know this — it surprises people.)
- **N+1 queries.** `@agency.advisors.each { |a| a.agency.name }` or listing many advisors each loading their agency fires one query per record. The fix is **eager loading**: `Advisor.includes(:agency)`. Mentioning N+1 and `includes` is a strong senior signal — we'll see it again in Step 04.
- **`dependent:` matters.** `:destroy` removes children; `:nullify` sets their FK to null; nothing leaves orphans. Pick deliberately.
- **Foreign key vs. validation.** `foreign_key: true` is a *database* constraint; `belongs_to` adds an *application* validation. Belt and suspenders — both are good.

## Check yourself
- [ ] In the console: `agency.advisors` and `advisor.agency` both work.
- [ ] Explain which table holds the foreign key and why.
- [ ] Explain `dependent: :destroy` and one alternative.
- [ ] Explain what an N+1 query is and how `includes` fixes it.
- [ ] The advisor form uses a dropdown of agency names.

## Interview talking points
- *"I modeled the host→advisor relationship with `has_many`/`belongs_to`; the foreign key lives on the advisors table as `agency_id`, and Rails generates the navigation methods from the association declarations."*
- *"`belongs_to` is required by default in modern Rails, so I think about whether a relationship is optional — and I use `dependent:` deliberately to avoid orphaned records, which matters for clean data during onboarding."*
- *"I watch for N+1 queries and eager-load with `includes` when rendering lists — same instinct I bring from the JS world."*

**Next:** `04-bookings-and-business-logic.md` — add Bookings, reach Agency→Bookings via `has_many :through`, and put real commission logic in the model.
