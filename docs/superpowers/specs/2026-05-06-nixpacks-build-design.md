# Nixpacks Build Migration — Design

**Date:** 2026-05-06
**Branch:** `nix-packs`
**Status:** Approved (pending user spec review)

## Motivation

Replace the hand-tuned multi-stage `Dockerfile` with [Nixpacks](https://nixpacks.com/) so Coolify (the deployment target) handles build configuration via auto-detection plus a small, in-repo `nixpacks.toml`. Goal: drop ongoing Dockerfile maintenance while preserving today's runtime contract exactly.

The runtime contract (start `bin/server` → `Release.migrate` → start release on `MIX_ENV=prod`) does not change. Only the *image producer* changes.

## Non-goals

- Switching off Mix releases.
- Changing how migrations are invoked (stays in `bin/server`, not split into a Coolify pre-deploy hook).
- Building Nixpacks images in CI (not in scope; only Coolify and local devs build with Nixpacks).
- Performance/size optimization beyond "image size doesn't bloat by >50%."

## Architecture

```
Source repo
   │
   ▼
nixpacks build .   (run by Coolify on deploy, or by devs locally for repro)
   │
   ├── setup:   install Nix pkgs (Elixir 1.16, Erlang 26, Node 22, git, openssl)
   ├── install: mix local.hex/rebar; mix deps.get --only prod; npm ci in assets/
   ├── build:   mix deps.compile → mix assets.deploy → mix compile → mix release
   │            → relocate release to /app/ so /app/bin/server is the entrypoint
   └── start:   /app/bin/server  (executes Release.migrate, then starts release)
```

## File changes

**Removed**
- `Dockerfile`
- `.dockerignore`
- `Dockerrun.aws.json` (Elastic Beanstalk-era; EB is off the table)

**Kept (Gigalixir fallback path; not in active use)**
- `Procfile`
- `elixir_buildpack.config`
- `phoenix_static_buildpack.config`

**Added**
- `nixpacks.toml`
- `.nixpacksignore` (analogous to `.dockerignore`; excludes `.squad/`, `memory-bank/`, `docs/`, `.github/`, build artifacts, secrets)

**Unchanged**
- `rel/overlays/bin/server` — runs migrate then starts the release
- `rel/overlays/bin/migrate` — release helper
- `lib/.../release.ex` — `Release.migrate` module
- `config/runtime.exs` — runtime env contract

## `nixpacks.toml` contents (target shape)

```toml
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
  # relocate release into /app so the start cmd is plain /app/bin/server.
  # exact mechanism (cp, symlink, or [phases.deploy] file filter)
  # is an implementation detail to be settled in the plan.
]

[start]
cmd = "/app/bin/server"

[variables]
MIX_ENV = "prod"
LANG = "en_US.UTF-8"
```

**Open implementation detail:** Nixpkgs may not expose `elixir_1_16` exactly — the actual package attr (e.g. `elixir_1_16_3`) will be pinned during plan execution against current Nixpkgs. Same for `erlang_26` and `nodejs_22`.

## Build pipeline

1. **Setup** — Nixpacks installs pinned Nix packages.
2. **Install** — Hex/Rebar local install; `mix deps.get --only prod`; `npm ci` in `assets/`.
3. **Build** — Compile deps; build minified assets via `mix assets.deploy` (tailwind + esbuild + phx.digest); compile app; build release; relocate to `/app/`.
4. **Start** — `/app/bin/server` runs `Release.migrate` then `start`.

This mirrors the current Dockerfile's two-stage layout (build then run) but expressed declaratively. The Phoenix provider in Nixpacks supplies sane defaults for any phase not overridden.

## Local dev workflow

- **Daily dev:** unchanged — `mix phx.server` is still the local driver.
- **Reproducing a production build:**
  ```sh
  nixpacks build . --name scc-phoenix
  docker run --rm -p 4000:4000 --env-file .env.prod-test scc-phoenix
  ```
- README gets a new short section: "Reproducing the production build."

## Coolify wiring

- Coolify project's "Build Pack" setting must be Nixpacks. With `Dockerfile` removed and `nixpacks.toml` present, Nixpacks is the unambiguous build path.
- No additional Coolify-side config needed beyond environment variables (already required by `config/runtime.exs`: `DATABASE_URL`, `SECRET_KEY_BASE`, etc.).
- Migrations: handled by `bin/server`. **No** Coolify pre-deploy command needed.

## Verification plan

The implementation is not done until all of the following pass.

### Local verification

1. `nixpacks build . --name scc-phoenix-test` completes without error.
2. `docker run --rm -p 4000:4000 --env-file .env.prod-test scc-phoenix-test` boots the app.
   - `.env.prod-test` supplies `DATABASE_URL`, `SECRET_KEY_BASE`, and any other required runtime env. `config/runtime.exs` is the source of truth for what's required.
3. Health check: `curl -fsS http://localhost:4000/<health-path>` returns 200. (Exact path resolved during plan: `heartcheck` is configured but actual route to be confirmed.)
4. **Migration check:** point `DATABASE_URL` at a fresh empty database; boot the image; confirm logs show `Release.migrate` ran and that expected tables exist.

### Image-size sanity check

`docker images scc-phoenix-test` — record size and compare to a `docker build .` of today's Dockerfile on the same machine. Flag if Nixpacks image is >50% larger.

### Coolify deploy verification

1. Push the branch to a non-prod Coolify environment first.
2. Confirm Coolify auto-detects Nixpacks (no Dockerfile present).
3. Build completes; container starts; health check passes.
4. Logs show `Release.migrate` ran on boot.
5. Smoke test: home page loads, login works, one GraphQL endpoint responds.

## Rollback

- If Coolify-side build/deploy fails: revert the merge commit (restores `Dockerfile` and `.dockerignore`).
- If Coolify itself becomes the problem: the retained `Procfile` + buildpack configs allow redirecting to Gigalixir as a backup deployment path.

## Risks & mitigations

| Risk | Mitigation |
| --- | --- |
| Nixpkgs Elixir/Erlang/Node attrs differ from `.tool-versions` exactly | Pin to nearest available patch; verify versions inside the built image during local verification. |
| Nixpacks Phoenix provider quietly skips `mix release` when it sees `mix phx.server` is possible | Override the build phase explicitly (above) so `mix release` always runs. |
| `assets.deploy` runs before `lib/` is fully present, breaking Tailwind JIT class scan | Nixpacks copies the full source into the build context before phases run, so Tailwind's class scan sees `.ex/.heex` files. Matches today's Dockerfile, which copies `lib/` before invoking `mix assets.deploy`. Verify during local build by spot-checking that compiled CSS contains classes that only appear in `.heex` files. |
| Image size bloats from default Nix store inclusion | Sanity check post-build; if >50% larger, revisit `[phases.deploy]` file filtering. |

## Out of scope (for follow-up if desired)

- Splitting migrations into a Coolify pre-deploy command.
- Building/testing Nixpacks images in CI.
- Removing Gigalixir fallback files once Coolify is proven stable.
- Image-size optimization beyond the bloat threshold.
