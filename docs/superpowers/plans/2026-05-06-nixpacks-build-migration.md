# Nixpacks Build Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the multi-stage `Dockerfile` with a small in-repo `nixpacks.toml` so Coolify builds the production image via Nixpacks, while preserving today's Mix-release runtime contract.

**Architecture:** Add `nixpacks.toml` (Phoenix provider + explicit phases) and `.nixpacksignore`. Keep `rel/overlays/bin/server` as the entrypoint that runs `Release.migrate` then starts the release. Once local + Coolify-staging verification pass, delete `Dockerfile`, `.dockerignore`, and `Dockerrun.aws.json`. Retain `Procfile` and Heroku/Gigalixir buildpack configs as a fallback.

**Tech Stack:** Nixpacks ≥ 1.x, Elixir 1.16, Erlang/OTP 26, Node 22.21.1, Phoenix 1.7, Mix releases, Coolify (deploy target), Postgres.

**Source spec:** `docs/superpowers/specs/2026-05-06-nixpacks-build-design.md`

---

## File Map

| File | Action | What changes |
|------|--------|--------------|
| `nixpacks.toml` | Create | Pinned Nix packages, install/build/start phases, env vars |
| `.nixpacksignore` | Create | Build-context exclusions (analogous to `.dockerignore`) |
| `Dockerfile` | Delete | Replaced by Nixpacks (Task 9, after verification) |
| `.dockerignore` | Delete | No longer needed (Task 9) |
| `Dockerrun.aws.json` | Delete | Elastic Beanstalk-era; off the table (Task 9) |
| `README.md` | Modify | Add "Reproducing the production build" section (Task 10) |
| `rel/overlays/bin/server` | Unchanged | Still the entrypoint |
| `rel/overlays/bin/migrate` | Unchanged | Release helper |
| `lib/stream_closed_captioner_phoenix/release.ex` | Unchanged | `Release.migrate` module |
| `config/runtime.exs` | Unchanged | Runtime env contract |
| `Procfile` | Unchanged | Kept as Gigalixir fallback |
| `elixir_buildpack.config` | Unchanged | Kept as Gigalixir fallback |
| `phoenix_static_buildpack.config` | Unchanged | Kept as Gigalixir fallback |

---

## Prerequisites

The engineer running this plan needs:

1. **Nixpacks CLI installed locally.** Verify: `nixpacks --version`. If missing on macOS: `brew install railwayapp/tap/nixpacks`. Other platforms: see https://nixpacks.com/docs/install.
2. **Docker running locally** (for `nixpacks build` and the boot test). Verify: `docker info`.
3. **A local Postgres reachable on `localhost:5432`** with credentials matching `config/dev.exs` (`postgres` / `postgres`). Verify: `psql -h localhost -U postgres -c '\l'` returns a list.
4. **A Coolify staging environment** wired to push-to-deploy from this repo (used in Task 11). Confirm with the operator before starting if unsure.

If any prerequisite is missing, install/start it before proceeding — do not skip ahead.

---

## Task 1: Resolve exact Nixpkgs attribute names

The spec uses placeholder attrs like `elixir_1_16` and `nodejs_22`. Nixpkgs may expose more specific names (e.g. `elixir_1_16_3`). This task pins the exact names we'll use in `nixpacks.toml`.

**Files:** none modified — this is a research/decision step. Record the chosen attrs as a comment in the next task's `nixpacks.toml`.

- [ ] **Step 1: Search Nixpkgs for the Elixir attr**

Run:

```bash
nix-env -f '<nixpkgs>' -qaP -A elixir 2>/dev/null | grep -E 'elixir_1_16|elixir-1\.16' | head -5
```

If you don't have a `<nixpkgs>` channel set, use the web search instead:

```bash
curl -s 'https://search.nixos.org/packages?channel=unstable&query=elixir_1_16&from=0&size=10' | grep -oE 'elixir_1_16[_0-9]*' | sort -u | head -5
```

**Expected output:** at least one of `elixir_1_16`, `elixir_1_16_0`, `elixir_1_16_3`. Record the most specific match that exists.

- [ ] **Step 2: Search for the Erlang attr**

```bash
curl -s 'https://search.nixos.org/packages?channel=unstable&query=erlang_26&from=0&size=10' | grep -oE 'erlang_26[_0-9]*' | sort -u | head -5
```

**Expected output:** `erlang_26` or `erlang_26_2_5` etc. Record the chosen attr.

- [ ] **Step 3: Search for the Node attr**

```bash
curl -s 'https://search.nixos.org/packages?channel=unstable&query=nodejs_22&from=0&size=10' | grep -oE 'nodejs_22[_0-9]*' | sort -u | head -5
```

**Expected output:** `nodejs_22`, `nodejs_22_11` etc. We want Node 22.21.1 (matches `.tool-versions`); pick the closest available `nodejs_22*` attr. Record it.

- [ ] **Step 4: Record the chosen attrs**

Write a one-line note for the next task. Example:

```
Chosen attrs: elixir_1_16, erlang_26, nodejs_22
(or whatever exact names Steps 1-3 returned)
```

No commit yet.

---

## Task 2: Create `.nixpacksignore`

Mirror `.dockerignore` so Nixpacks doesn't ship the world into the build context.

**Files:**
- Create: `.nixpacksignore`

- [ ] **Step 1: Create the file**

Create `.nixpacksignore` with this exact content:

```
.git
!.git/HEAD
!.git/refs

# Common development/test artifacts
/cover/
/doc/
/test/
/tmp/
.elixir_ls

# Mix artifacts
/_build/
/deps/
*.ez

# Generated on crash by the VM
erl_crash.dump

# Static artifacts - fetched and built inside the image
/assets/node_modules/
/priv/static/assets/
/priv/static/cache_manifest.json

# Squad / planning / docs (not needed in image)
/.squad/
/memory-bank/
/.github/
/docs/

# Local secrets — must NEVER ship in the build context
.env
.env.*
!.env.example
```

- [ ] **Step 2: Commit**

```bash
git add .nixpacksignore
git commit -m "$(cat <<'EOF'
build: add .nixpacksignore mirroring .dockerignore

Excludes vcs metadata, dev artifacts, build outputs, planning docs,
and any .env files from the Nixpacks build context.
EOF
)"
```

Expected: clean commit, working tree shows only the unrelated `mix.exs` / `config/dev.exs` modifications still pending.

---

## Task 3: Create initial `nixpacks.toml` (without release relocation)

Build the toml in two passes: first prove it can produce a working image, *then* (Task 7) refactor to relocate the release for a clean `/app/bin/server` start path. This keeps each diff small and verifiable.

**Files:**
- Create: `nixpacks.toml`

- [ ] **Step 1: Create the file**

Create `nixpacks.toml` with this exact content (substitute the exact attrs from Task 1 if they differ):

```toml
# Nixpacks build config for Coolify deploys.
# Pinned to .tool-versions (elixir 1.16.0, erlang 26.0, nodejs 22.21.1).
providers = ["phoenix"]

[phases.setup]
nixPkgs = ["elixir_1_16", "erlang_26", "nodejs_22", "git", "openssl"]

[phases.install]
cmds = [
  "mix local.hex --force",
  "mix local.rebar --force",
  "mix deps.get --only prod",
  "npm --prefix assets ci --no-audit --progress=false",
]

[phases.build]
cmds = [
  "mix deps.compile",
  "mix assets.deploy",
  "mix compile",
  "mix release",
]

[start]
cmd = "/app/_build/prod/rel/stream_closed_captioner_phoenix/bin/server"

[variables]
MIX_ENV = "prod"
LANG = "en_US.UTF-8"
```

- [ ] **Step 2: Commit**

```bash
git add nixpacks.toml
git commit -m "$(cat <<'EOF'
build: add initial nixpacks.toml

Uses the Phoenix provider with explicit setup/install/build phases pinned
to .tool-versions. Start cmd points at the in-release bin/server path;
Task 7 relocates the release for a cleaner /app/bin/server entrypoint.
EOF
)"
```

---

## Task 4: First local Nixpacks build — verify image is produced

Run `nixpacks build` and iterate on `nixpacks.toml` until it produces a working image. This is the hardest task in the plan because Nixpacks behavior varies slightly across versions. Common gotchas are inlined below.

**Files:**
- Possibly modify: `nixpacks.toml` (only if a fix is needed; commit any fix)

- [ ] **Step 1: Build the image**

Run from the repo root:

```bash
nixpacks build . --name scc-phoenix-test
```

**Expected output:** ends with `Successfully built ...` and `docker images scc-phoenix-test` lists a fresh image.

- [ ] **Step 2: If the build fails — diagnose**

Read the error message carefully. Common failure modes and fixes:

| Symptom | Likely cause | Fix |
|---|---|---|
| `attribute 'elixir_1_16' missing` | The exact attr doesn't exist in Nixpkgs at the channel Nixpacks uses | Replace with the attr you found in Task 1 (e.g. `elixir_1_16_3`) |
| `mix: command not found` during install | Phoenix provider didn't pull Elixir into the install phase | Confirm `elixir_*` is in `[phases.setup].nixPkgs`; rebuild |
| `npm: command not found` | Node attr name wrong | Use the attr from Task 1 step 3 |
| `Could not start application stream_closed_captioner_phoenix` during `mix release` | App tries to connect to DB at compile time | Should not happen for this project; if it does, set `RUNTIME_ENV` env in `[variables]` and re-check `config/runtime.exs` |
| `error: lib not found` while running `mix assets.deploy` | Source not yet copied at build phase start | Reorder phases — the toml above already has `mix compile` before `mix release`; ensure `mix assets.deploy` runs after `mix deps.compile` (it does in the toml above) |
| Tailwind compiles but classes from `.heex` are missing in CSS | Tailwind ran before `lib/` was present | This shouldn't happen since Nixpacks copies the full source before phases run; if it does, verify `.nixpacksignore` does NOT exclude `lib/` |

- [ ] **Step 3: Apply any fix and re-run**

If you edited `nixpacks.toml`, re-run:

```bash
nixpacks build . --name scc-phoenix-test
```

Expected: build succeeds.

- [ ] **Step 4: Verify the image has the release at the expected path**

```bash
docker run --rm --entrypoint sh scc-phoenix-test -c 'ls /app/_build/prod/rel/stream_closed_captioner_phoenix/bin/'
```

**Expected output:** lists `server`, `migrate`, `stream_closed_captioner_phoenix`, etc. If empty or missing: the release wasn't built — re-check the `[phases.build]` cmds.

- [ ] **Step 5: Commit any toml fixes (only if you edited the toml in Step 3)**

```bash
git add nixpacks.toml
git commit -m "build: fix nixpacks.toml for local build (<short reason>)"
```

If no fixes were needed, skip the commit.

---

## Task 5: Boot the image and verify the health check

Confirm the produced image actually starts Phoenix and serves a 200 from `/monitoring` (the existing HeartCheck endpoint at `lib/stream_closed_captioner_phoenix_web/router.ex:102`).

**Files:**
- Create: `.env.prod-test` (gitignored — do NOT commit)

- [ ] **Step 1: Confirm `.env.prod-test` is gitignored**

```bash
grep -E '^\.env\.|^\.env\*|^\.env$' .gitignore
```

**Expected output:** at least one line matching `.env*` or `.env.prod-test`. If nothing matches, add `/.env.prod-test` to `.gitignore` and commit that change separately:

```bash
echo '/.env.prod-test' >> .gitignore
git add .gitignore
git commit -m "chore: ignore local .env.prod-test for nixpacks smoke testing"
```

- [ ] **Step 2: Generate two secrets we need**

```bash
docker run --rm scc-phoenix-test \
  /app/_build/prod/rel/stream_closed_captioner_phoenix/bin/stream_closed_captioner_phoenix eval \
  ':crypto.strong_rand_bytes(48) |> Base.encode64() |> IO.puts()'
```

Run that twice. Save the two outputs as `SECRET_KEY_BASE` and `LIVE_SIGNING_SALT`.

- [ ] **Step 3: Create `.env.prod-test`**

Create `.env.prod-test` in the repo root (NOT committed):

```
# Local smoke test only. DO NOT commit this file.
USE_SSL=false
RDS_USERNAME=postgres
RDS_PASSWORD=postgres
RDS_DB_NAME=scc_nixpacks_test
RDS_HOSTNAME=host.docker.internal
POOL_SIZE=2
PORT=4000
HOST=localhost

SECRET_KEY_BASE=<paste first secret from Step 2>
LIVE_SIGNING_SALT=<paste second secret from Step 2>

# Twitch — fetch_env! requires this; any non-empty string works for boot
TWITCH_TOKEN_SECRET=local-test-not-used
TWITCH_CLIENT_ID=local-test
TWITCH_CLIENT_SECRET=local-test
TWITCH_REDIRECT_URI=http://localhost:4000/auth/twitch/callback

# Optional but referenced
GUARDIAN_SECRET_KEY=local-test
EVENTSUB_CALLBACK_URL=http://localhost:4000/eventsub
NOTION_API_KEY=local-test
NOTION_VERSION=2022-06-28
SENDGRID_API_KEY=local-test
CACHE_ALLOCATED_MEMORY=536870912
```

- [ ] **Step 4: Create the test database**

```bash
psql -h localhost -U postgres -c 'DROP DATABASE IF EXISTS scc_nixpacks_test;'
psql -h localhost -U postgres -c 'CREATE DATABASE scc_nixpacks_test;'
```

**Expected output:** `DROP DATABASE` (or `NOTICE`) then `CREATE DATABASE`.

- [ ] **Step 5: Boot the container**

```bash
docker run --rm -d --name scc-phoenix-smoketest \
  --add-host=host.docker.internal:host-gateway \
  -p 4000:4000 --env-file .env.prod-test \
  scc-phoenix-test
```

**Expected output:** a container ID. Then wait a few seconds for boot:

```bash
sleep 10 && docker logs scc-phoenix-smoketest 2>&1 | tail -50
```

**Expected output excerpt:** lines including `Migrations`, `Running StreamClosedCaptionerPhoenixWeb.Endpoint`, and `Access at http://...:4000`. No `(RuntimeError)` lines.

- [ ] **Step 6: Hit the health endpoint**

```bash
curl -fsS -o /dev/null -w 'HTTP %{http_code}\n' http://localhost:4000/monitoring
```

**Expected output:** `HTTP 200`.

- [ ] **Step 7: Stop and clean up**

```bash
docker stop scc-phoenix-smoketest
```

No commit (test artifacts are not committed).

---

## Task 6: Verify migrations actually ran on boot

Independent of the health check passing, prove `Release.migrate` executed against a fresh database during Task 5's boot.

**Files:** none modified.

- [ ] **Step 1: Inspect the migrations table**

```bash
psql -h localhost -U postgres -d scc_nixpacks_test \
  -c 'SELECT count(*) FROM ecto_schema_migrations;'
```

**Expected output:** a count > 0 (matches `priv/repo/migrations/` file count).

- [ ] **Step 2: Compare to migration files on disk**

```bash
ls priv/repo/migrations/ | wc -l
```

**Expected output:** the same count (or one less, if there's a single non-`.exs` file in that directory — verify by `ls priv/repo/migrations/ | grep -c '\.exs$'`).

- [ ] **Step 3: Spot-check a known table exists**

```bash
psql -h localhost -U postgres -d scc_nixpacks_test \
  -c '\dt' | head -20
```

**Expected output:** lists tables including `users` (or whatever the project's first migrated table is — confirm by inspecting `priv/repo/migrations/0*_create_users.exs` or similar).

If migrations did not run: re-read `docker logs scc-phoenix-smoketest` from Task 5 — there will be a `Release.migrate` error.

No commit.

---

## Task 7: Refactor build phase to relocate the release into `/app/`

Now that the build is proven, give it a clean entrypoint at `/app/bin/server`.

**Files:**
- Modify: `nixpacks.toml`

- [ ] **Step 1: Update `[phases.build]` and `[start]`**

Edit `nixpacks.toml`. Replace the `[phases.build]` and `[start]` blocks with:

```toml
[phases.build]
cmds = [
  "mix deps.compile",
  "mix assets.deploy",
  "mix compile",
  "mix release",
  # Relocate the release into /app/ so the start command is /app/bin/server.
  # We move (not copy) to avoid doubling the image's release size.
  "rm -rf /tmp/scc-release && mv _build/prod/rel/stream_closed_captioner_phoenix /tmp/scc-release && rm -rf /app/* && mv /tmp/scc-release/* /app/",
]

[start]
cmd = "/app/bin/server"
```

The `rm -rf /app/*` step intentionally clears the build context from `/app/` so the runtime image only carries the release. Source files, deps, `_build/`, etc. are no longer needed once the release is built.

- [ ] **Step 2: Rebuild**

```bash
nixpacks build . --name scc-phoenix-test
```

**Expected output:** `Successfully built ...`.

- [ ] **Step 3: Verify the new entrypoint exists**

```bash
docker run --rm --entrypoint sh scc-phoenix-test -c 'ls /app/bin/'
```

**Expected output:** lists `server`, `migrate`, `stream_closed_captioner_phoenix`.

- [ ] **Step 4: Re-run the smoke test from Task 5 against the new image**

```bash
docker run --rm -d --name scc-phoenix-smoketest \
  --add-host=host.docker.internal:host-gateway \
  -p 4000:4000 --env-file .env.prod-test \
  scc-phoenix-test
sleep 10
curl -fsS -o /dev/null -w 'HTTP %{http_code}\n' http://localhost:4000/monitoring
docker stop scc-phoenix-smoketest
```

**Expected output:** `HTTP 200`.

- [ ] **Step 5: Commit**

```bash
git add nixpacks.toml
git commit -m "$(cat <<'EOF'
build: relocate release to /app/ for clean start command

The build phase now moves the mix release into /app/ and removes the
build context, so the start command is /app/bin/server (matching the
prior Dockerfile's entrypoint).
EOF
)"
```

---

## Task 8: Image size sanity check

Compare the Nixpacks image to today's Dockerfile-built image. Flag if Nixpacks bloats by >50%.

**Files:** none modified.

- [ ] **Step 1: Build the current Dockerfile image for comparison**

```bash
docker build -t scc-phoenix-docker-baseline .
```

**Expected output:** `Successfully tagged scc-phoenix-docker-baseline:latest`. (If this fails because of removed/changed compile-time env, skip the comparison and note that in Step 3.)

- [ ] **Step 2: Compare sizes**

```bash
docker images --format 'table {{.Repository}}\t{{.Size}}' \
  | grep -E 'scc-phoenix-(test|docker-baseline)'
```

**Expected output:** two lines with sizes. Calculate the ratio.

- [ ] **Step 3: Record the result**

If Nixpacks image ≤ 1.5× baseline: pass, proceed.

If Nixpacks image > 1.5× baseline: pause and investigate. Common causes: Nix store carrying compilers/build tools into runtime. Mitigation options (do not implement now — surface to the operator):
- Add `[phases.deploy]` with `onlyIncludeFiles = ["bin/", "lib/", "releases/", "erts-*"]` to filter what carries to the runtime layer.
- Or revisit whether the move-and-clear in Task 7 actually cleared what it should.

Record the comparison result (e.g. "Nixpacks 280MB vs Docker 240MB — 1.17×, within budget") for the eventual PR description.

No commit.

---

## Task 9: Remove legacy Docker / EB files

With Nixpacks proven locally, remove the files Coolify and devs no longer need. Keep Gigalixir-related files as a fallback.

**Files:**
- Delete: `Dockerfile`
- Delete: `.dockerignore`
- Delete: `Dockerrun.aws.json`

- [ ] **Step 1: Confirm the keepers are present (do NOT delete these)**

```bash
ls Procfile elixir_buildpack.config phoenix_static_buildpack.config
```

**Expected output:** all three listed. If any are missing, STOP and check git history before continuing.

- [ ] **Step 2: Delete the legacy files**

```bash
git rm Dockerfile .dockerignore Dockerrun.aws.json
```

**Expected output:** three `rm 'X'` lines.

- [ ] **Step 3: Sanity-check the working tree**

```bash
git status
```

**Expected output:**
- `deleted: Dockerfile`
- `deleted: .dockerignore`
- `deleted: Dockerrun.aws.json`
- (Plus the unrelated pending changes to `mix.exs` and `config/dev.exs` — leave those alone.)
- (Plus untracked `AGENTS.md`, `squad-export.json` — leave those alone.)

- [ ] **Step 4: Commit**

```bash
git commit -m "$(cat <<'EOF'
build: remove Dockerfile, .dockerignore, Dockerrun.aws.json

Nixpacks (configured via nixpacks.toml) is now the production image
producer. Procfile and Heroku/Gigalixir buildpack configs are kept as
a fallback deployment path.
EOF
)"
```

---

## Task 10: Document the local build workflow in `README.md`

Add a short section so future contributors know how to reproduce the production build.

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Read the current README**

```bash
cat README.md
```

Note the existing section headers — we'll insert the new section after the "Migrate database" section and before "Debugging on Elastic Beanstalk".

- [ ] **Step 2: Add the new section**

Edit `README.md` and insert this section after the line `bin/stream_closed_captioner_phoenix eval "StreamClosedCaptionerPhoenix.Release.migrate"` and before the `## Debugging on Elastic Beanstalk` heading. The block below uses quad-backtick fences only so the inner triple-backtick `sh` block survives copy-paste — when you paste, replace the outer quad fences with the start/end of your edit (don't paste the quad-backticks themselves):

`````markdown
## Reproducing the production build

Production images are built by [Nixpacks](https://nixpacks.com/) (configured in `nixpacks.toml`) and deployed via Coolify. To reproduce locally:

```sh
nixpacks build . --name scc-phoenix
docker run --rm -p 4000:4000 --env-file .env.prod-test scc-phoenix
```

`.env.prod-test` is gitignored — see `config/runtime.exs` for the required environment variables. At minimum you need `SECRET_KEY_BASE`, `LIVE_SIGNING_SALT`, `TWITCH_TOKEN_SECRET`, and either `DATABASE_URL` (with `USE_SSL=true`) or the `RDS_*` set.

The container starts with `/app/bin/server`, which runs `Release.migrate` and then boots Phoenix on port 4000.
`````

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "$(cat <<'EOF'
docs: add Reproducing the production build section to README

Documents the nixpacks build / docker run workflow and points to
config/runtime.exs as the source of truth for required env vars.
EOF
)"
```

---

## Task 11: Verify Coolify staging deploy

Push the branch to a Coolify-watched non-prod environment and confirm the deploy works end-to-end. This is the only task that touches a remote environment — go slowly.

**Files:** none modified locally.

- [ ] **Step 1: Confirm the staging Coolify project is configured for Nixpacks**

This is a manual check in the Coolify UI. The project's "Build Pack" setting must be `Nixpacks`. If it's currently `Dockerfile`, switch it to `Nixpacks` *before* pushing the branch (otherwise Coolify will fail looking for a Dockerfile that no longer exists).

If you don't have access to the Coolify UI: stop here and ask the operator. Do not push the branch yet.

- [ ] **Step 2: Push the branch**

```bash
git push origin nix-packs
```

**Expected output:** the push succeeds. Coolify should auto-pick-up the push and start a build (depends on project config).

- [ ] **Step 3: Watch the Coolify build log**

Open the staging deployment's build log in the Coolify UI. Look for:
- "Detected Nixpacks" (or equivalent — Coolify announces which builder it chose).
- The phases from `nixpacks.toml` running in order: setup → install → build → start.
- Build completes without error.

**If the build fails:** read the error, fix locally if reproducible (re-run Task 4 for the same error class), commit, push. Do NOT keep retrying without a code change.

- [ ] **Step 4: Confirm the container starts and the health check passes**

```bash
curl -fsS -o /dev/null -w 'HTTP %{http_code}\n' https://<staging-host>/monitoring
```

(Substitute the actual staging hostname.)

**Expected output:** `HTTP 200`.

- [ ] **Step 5: Confirm `Release.migrate` ran on boot**

In the Coolify UI, view the deployed container's runtime logs. Search for `Release.migrate` or `Migrations`. Confirm at least one line indicates migrations were processed.

- [ ] **Step 6: Smoke-test three flows**

In a browser pointed at the staging host:
1. Load the home page — should render without errors.
2. Log in via Twitch OAuth (use a test account if available) — should redirect through and back successfully.
3. Hit one GraphQL endpoint — e.g. `curl -fsS https://<staging-host>/graphql -H 'content-type: application/json' -d '{"query":"{ __typename }"}'` should return `{"data":{"__typename":"RootQueryType"}}`.

**If any flow fails:** capture the error, do NOT proceed to Task 12. Roll back the staging deploy via Coolify (redeploy the previous commit) and triage the failure.

- [ ] **Step 7: Record the staging verification result**

Note the staging deploy URL, build duration, and any quirks observed for the PR description in Task 12.

No commit.

---

## Task 12: Open a pull request

Create a PR against `master` so the change can land production.

**Files:** none modified.

- [ ] **Step 1: Confirm branch is clean and ready**

```bash
git status
git log --oneline master..HEAD
```

**Expected output:** working tree shows only the unrelated pre-existing changes (`mix.exs`, `config/dev.exs`); `git log` shows the commits added by Tasks 2, 3, 7, 9, 10 (and any fix commits from Task 4).

- [ ] **Step 2: Push (if any commits weren't pushed in Task 11)**

```bash
git push origin nix-packs
```

- [ ] **Step 3: Open the PR**

```bash
gh pr create --base master --title "build: replace Dockerfile with Nixpacks for Coolify" --body "$(cat <<'EOF'
## Summary
- Replace the multi-stage `Dockerfile` with `nixpacks.toml` (Phoenix provider + explicit phases) so Coolify builds via Nixpacks.
- Preserve the runtime contract exactly: `/app/bin/server` runs `Release.migrate` then starts the Mix release on `MIX_ENV=prod`.
- Keep `Procfile`, `elixir_buildpack.config`, `phoenix_static_buildpack.config` as a Gigalixir fallback. Remove `Dockerfile`, `.dockerignore`, `Dockerrun.aws.json`.

Spec: `docs/superpowers/specs/2026-05-06-nixpacks-build-design.md`
Plan: `docs/superpowers/plans/2026-05-06-nixpacks-build-migration.md`

## Test plan
- [x] Local `nixpacks build .` succeeds
- [x] Container boots; `GET /monitoring` returns 200
- [x] `Release.migrate` runs on boot against a fresh DB; `ecto_schema_migrations` populated
- [x] Image size within 1.5× current Dockerfile baseline
- [x] Coolify staging deploy succeeds; health check passes; smoke flows pass (home page, Twitch login, GraphQL `__typename`)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

**Expected output:** a PR URL. Capture it.

- [ ] **Step 4: Final cleanup**

Remove the local test artifacts (not committed, just disk hygiene):

```bash
rm -f .env.prod-test
docker rmi scc-phoenix-test scc-phoenix-docker-baseline 2>/dev/null || true
psql -h localhost -U postgres -c 'DROP DATABASE IF EXISTS scc_nixpacks_test;'
```

No commit.

---

## Done

When all tasks are complete:
- `nixpacks.toml` and `.nixpacksignore` are committed.
- `Dockerfile`, `.dockerignore`, `Dockerrun.aws.json` are removed.
- `README.md` documents the local Nixpacks workflow.
- Coolify staging deploy passed verification.
- A PR is open against `master` with a green test plan.

The unrelated working-tree changes to `mix.exs` and `config/dev.exs` should still be present and untouched.
