# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Companion docs (read these too)

- **`.github/copilot-instructions.md`** — authoritative, project-specific guide: caption flow, service-provider Mox pattern, billing/translation paths, presence/tracking, caching, auth, GraphQL, Oban, factory caveats. **Start here for "how does this app work" questions.**
- **`AGENTS.md`** — generic Phoenix/Elixir/Ecto/LiveView usage rules (HEEx syntax, streams, form patterns, etc.). Treat as framework conventions, not project-specific.

If the two conflict on a project specific topic, `.github/copilot-instructions.md` wins.

## Commands

```bash
mix setup              # Install deps, create & migrate DB, build assets
mix test               # Full suite (creates/migrates DB first via the test alias)
mix test path/to/file_test.exs       # Single file
mix test path/to/file_test.exs:42    # Single test at line
mix test --failed                    # Re-run previously failed tests
mix lint               # Credo
mix security           # Sobelow
mix phx.server         # Dev server (port 4000)
mix start.debug        # iex -S mix phx.server
mix routes             # List all routes
mix ecto.reset         # Drop, recreate, migrate, re-seed
mix coveralls.html     # Coverage report
mix precommit          # Run before finishing changes (per AGENTS.md)
```

Production migrations: `bin/stream_closed_captioner_phoenix eval "StreamClosedCaptionerPhoenix.Release.migrate"`.

## Architecture at a glance

Phoenix 1.8 app split into the standard two trees under `lib/`:

- **`stream_closed_captioner_phoenix/`** — contexts and domain (Accounts, Bits, Settings, Transcripts, CaptionsPipeline, Jobs, Services, Cache).
- **`stream_closed_captioner_phoenix_web/`** — controllers, channels, LiveViews, GraphQL (Absinthe) schema/resolvers, plugs, components.

Supervised children (`application.ex`): libcluster, Repo, Telemetry, PubSub, Endpoint, `UserTracker` (Phoenix.Tracker), `Absinthe.Subscription`, `Cache` (Nebulex), Oban.

The **caption pipeline** is the product:
client transcribes → `CaptionsChannel` (Phoenix Channel `captions:USER_ID`) → `CaptionsPipeline` (censor → pirate → translate) → fan-out to Twitch (via Absinthe subscription `new_twitch_caption`), Zoom live captions API, or `transcript:1` PubSub topic. See copilot-instructions for full detail.

## Project-specific quirks to know

- **Migration table is renamed.** `config/dev.exs` sets `migration_source: "ecto_schema_migrations"` — the app was migrated from a Rails origin that owns `schema_migrations`. Don't change this; new migrations should keep using `mix ecto.gen.migration ...`.
- **Timestamps use `created_at`, not `inserted_at`.** Schemas declare `timestamps(inserted_at: :created_at)`. Audit logs add `updated_at: false`.
- **External services are behaviour-injected.** `Azure.api_client()`, `Twitch.ext_api_client()`, `Twitch.helix_api_client()` resolve at runtime from app config — swapped to Mox mocks in tests (`Azure.MockCognitive`, `Twitch.MockExtension`, `Twitch.MockHelix`, defined in `test/test_helper.exs`).
- **Sensitive fields.** `User` has `@derive {Inspect, except: [...]}`; `azure_service_key` uses the `EncryptedBinary` Ecto type (AES-256-GCM, `ENCRYPTION_KEY` env var). Mutations to sensitive resources should call `StreamClosedCaptionerPhoenix.Audit.log_azure_key_action/3`.
- **Factory associations are pre-built.** `insert(:user)` already creates `stream_settings` and `bits_balance` — update them, don't insert new ones alongside.
- **Oban in tests is `:manual`** — jobs don't run automatically; use `perform_job/2`. Queues are `default` and `events` (10 workers each).
- **Admin is gated by `user.uid == "120750024"`** via the `:admin_protected` pipeline (protects `/live-dashboard` and `/feature-flags`).
- **HTTP to Azure**: use `HTTPoison.post` (not `post!`) and scrub sensitive data before logging on the error path. For new HTTP needs, `Req` is preferred (per AGENTS.md), but existing Azure code is HTTPoison-based — match the surrounding style.

## Toolchain version pins (keep in sync)

OTP/Elixir versions are declared in several places that must move together when bumped. **`.tool-versions` is the source of truth**; `jose` requires OTP 27 (native `json` module, `dynamic()` type), so none of these may drop below OTP 27. After pulling a toolchain bump, local dev must run `asdf install` — an older OTP (25/26) will hit `jose` compile errors:

- **`.tool-versions`** — local dev (asdf); source of truth (`erlang`, `elixir`, `nodejs`).
- **`nixpacks.toml`** — production build (`beam.packages.erlang_27.elixir_1_19`, `nodejs_22`) + its pinned `nixpkgsArchive`. Note Node is pinned here by Nix *major* attr (`nodejs_22`) while `.tool-versions` pins a patch (`22.x`), so a Node-major bump also needs this attr updated.
- **`.github/workflows/test-coverage.yml`** — CI (`ELIXIR_VERSION` / `OTP_VERSION` env).
- **`.github/workflows/copilot-setup-steps.yml`** and **`.github/workflows/shared/elixir-setup.md`** — GitHub Copilot Agent (`erlef/setup-beam` pins). These two have diverged (different Postgres setup, extra steps) and are **not** generated from one another — keep them in sync manually.
- **`.claude/hooks/session-start.sh`** — Claude Code web sessions; **reads OTP/Elixir from `.tool-versions`** (no separate pin), but the Ubuntu/arch and Hex-series assumptions live here.

## Production / deploy

Built with **Nixpacks** (`nixpacks.toml`), deployed via Coolify. Reproduce locally:

```sh
nixpacks build . --name scc-phoenix
docker run --rm -p 4000:4000 --env-file .env.prod-test scc-phoenix
```

Required env vars are documented in `config/runtime.exs`; key ones: `SECRET_KEY_BASE`, `LIVE_SIGNING_SALT`, `ENCRYPTION_KEY`, `TWITCH_CLIENT_ID/SECRET`, `TWITCH_TOKEN_SECRET`, `AZURE_COGNITIVE_KEY`, `DEEPGRAM_TOKEN`, `METRICS_AUTH_TOKEN` (bearer token protecting `/metrics`), and either `DATABASE_URL` (with `USE_SSL=true`) or the `RDS_*` set.

The container entrypoint is `/app/bin/server`, which runs `Release.migrate` then boots Phoenix on `4000`.
