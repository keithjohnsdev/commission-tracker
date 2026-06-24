# Step 00 — Environment Setup (macOS + Ruby + Rails)

## Goal
Get a working Rails dev environment on your **MacBook Pro**, install **Ruby 3.3.x** and **Rails 8**, and generate + run an empty app so `http://localhost:3000` shows the Rails welcome page.

## Why this matters (and the interview angle)
macOS is **Unix-based**, which is exactly what Rails expects — the same family as the Linux servers Rails runs on in production. No WSL, no VM, no workarounds: Ruby compiles and runs natively, file-watching is fast, and gems behave the way the Rails guides assume. You can honestly say *"I develop Rails on macOS with rbenv-managed Ruby"* — the canonical Rails setup (Rails itself was built on a Mac).

> **Why not Windows/WSL?** Native Windows isn't a real Rails environment, so on a PC you'd install WSL2 just to *get* Unix. Your Mac already is Unix — so you skip all of that. This doc replaces the old WSL version.

---

## Part A — Install Homebrew (the Mac package manager)

**Homebrew** is how you install developer tools on macOS (`brew install ...`). One-time setup.

1. Open **Terminal** (Cmd+Space → type "Terminal" → Enter).
2. Install Homebrew:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
3. After it finishes, it may print **"Next steps"** telling you to add Homebrew to your PATH. On Apple Silicon Macs (M1/M2/M3) that's:
   ```bash
   echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
   eval "$(/opt/homebrew/bin/brew shellenv)"
   ```
   (On older Intel Macs Homebrew lives at `/usr/local` and PATH usually works without this.)
4. Confirm it works:
   ```bash
   brew -v        # should print a Homebrew version
   ```

> **Note:** macOS uses **zsh** as its default shell, so your config file is `~/.zshrc` / `~/.zprofile` (not `~/.bashrc`). If a guide says `.bashrc`, use `.zshrc` on your Mac.

---

## Part B — Install build dependencies

Ruby and many gems compile native (C) extensions. Most of what you need ships with the **Xcode Command Line Tools**, plus a couple of libraries via Homebrew.

```bash
# Apple's compiler toolchain (git, make, clang, etc.) — one-time, may open a dialog
xcode-select --install

# Libraries that prevent classic Ruby-build failures
brew install openssl@3 readline libyaml gmp
```

**Why:** `libyaml` and `openssl` in particular are the usual culprits behind failed Ruby installs; installing them up front avoids the common errors.

---

## Part C — Install Ruby with rbenv (a version manager)

We use **rbenv** so you can manage Ruby versions cleanly (real projects pin a specific version).

```bash
# Install rbenv + the ruby-build plugin via Homebrew
brew install rbenv ruby-build

# Wire rbenv into your shell
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
source ~/.zshrc

# Confirm rbenv is on PATH
rbenv -v
```

Now install Ruby (this compiles — takes a few minutes):

```bash
rbenv install 3.3.6      # or the latest stable 3.3.x / 3.4.x
rbenv global 3.3.6
ruby -v                  # should print ruby 3.3.6
```

> **Gotcha:** if `ruby -v` still shows the system Ruby (often `2.6.x` or `3.0.x` at `/usr/bin/ruby`), your shell didn't pick up rbenv. Run `source ~/.zshrc` or open a new Terminal tab, then check `which ruby` — it should point inside `~/.rbenv/shims`, **not** `/usr/bin/ruby`. Never use the system Ruby for development.

---

## Part D — Install Rails

```bash
# Speed up gem installs by skipping local docs
echo "gem: --no-document" >> ~/.gemrc

gem install rails        # installs the latest Rails (8.x)
rbenv rehash             # makes the new `rails` command visible to rbenv
rails -v                 # should print Rails 8.x
```

> Rails 8 includes **Hotwire (Turbo + Stimulus) by default** and uses **importmaps**, so you do **not** need Node/Yarn for this project.

---

## Part E — Choose where the app lives

On a Mac there's **no filesystem-bridge penalty** (the thing that made `/mnt/c` slow on Windows/WSL) — put the app wherever you like. We're keeping it next to the `tern-prep` repo, in `~/Desktop/tern`:

```bash
cd ~/Desktop/tern
```

> **Tip:** the **app** lives at `~/Desktop/tern/commission_tracker` and the **learning docs** stay in the `tern-prep` repo (`~/Desktop/tern/tern-prep`) — two separate sibling folders. Keeping them apart is cleaner: the app becomes its own portfolio repo (doc 09). Recommended: keep them separate (don't generate the app inside `tern-prep`).

Open the project in your editor — VS Code: `code .` from the app folder (install the `code` command via Cmd+Shift+P → "Shell Command: Install 'code' command in PATH" if needed).

---

## Part F — Generate and run the app

```bash
# from ~/Desktop/tern (or your chosen dir)
rails new commission_tracker
cd commission_tracker
bin/rails server
```

Open **http://localhost:3000** in your browser → you should see the **Rails welcome page**. 🎉

Stop the server with `Ctrl+C`.

> **Database note (important talking point):** `rails new` defaults to **SQLite** — zero setup, perfect for learning, and Rails 8 made SQLite genuinely production-capable for small apps. **Tern uses PostgreSQL.** They're both SQL databases Active Record talks to identically for our purposes; the difference is mostly operational (concurrency, scaling, hosting). If you'd matched Tern exactly you'd run `rails new commission_tracker -d postgresql` and install Postgres (`brew install postgresql@16`) — we're using SQLite to remove friction, and doc 09 explains how/why you'd switch. **Know this distinction cold; it's a likely question.**

---

## Part G — Initialize git (do this now)

```bash
# inside commission_tracker (rails new already runs git init)
git add -A
git commit -m "Initial Rails 8 app skeleton"
```

You'll commit after each step → clean history + a portfolio repo (push to GitHub later; see your `career/` plan).

---

## Things to look out for
- **Don't use the system Ruby** (`/usr/bin/ruby`). Always work through rbenv — `which ruby` should point at `~/.rbenv/shims/ruby`.
- **Don't `sudo gem install`** — with rbenv you never need sudo for Ruby gems. If a guide tells you to sudo, that's a sign rbenv isn't set up right.
- If `bin/rails server` says the port is in use, another server is running — find/stop it or use `bin/rails server -p 3001`.
- Apple Silicon vs Intel: Homebrew lives at `/opt/homebrew` (Apple Silicon) or `/usr/local` (Intel). If `brew` isn't found, that PATH line in Part A is why.
- Your shell is **zsh** — edit `~/.zshrc`, not `~/.bashrc`.

## Check yourself
- [ ] `ruby -v` → 3.3.x and `which ruby` points inside `~/.rbenv/shims`
- [ ] `rails -v` → 8.x
- [ ] `http://localhost:3000` shows the Rails welcome page
- [ ] You made your first git commit
- [ ] You can explain, in one sentence, **why macOS is a natural Rails environment** and **the SQLite-vs-Postgres tradeoff**

## Interview talking points (say these out loud)
- *"I develop Rails on macOS with rbenv-managed Ruby — a Unix environment that matches how Rails runs in production."*
- *"Rails 8 ships with Hotwire and importmaps by default, so I didn't even need a Node build step."*
- *"I used SQLite for the learning build since Rails 8 made it production-viable for small apps; Tern uses Postgres — Active Record abstracts the database, so the app code is the same, the difference is operational."*

**Next:** `01-rails-fundamentals.md` — a tour of what `rails new` actually created, and how a request flows through the app.
