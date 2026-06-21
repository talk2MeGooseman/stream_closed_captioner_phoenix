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
- **HTTP via `Req`**: all external service adapters use `Req` (per AGENTS.md; `:httpoison`/`:hackney` survive only as transitive deps of neuron/bamboo/libcluster_ec2). Use the non-raising `Req.get`/`Req.post`/etc. (they return `{:ok, resp} | {:error, exception}`) and pattern-match the result — never the `!` variants. Shared options come from `Helpers.req_options/1` (supervised `Finch` pool, `retry: false`, `decode_body: false`, connect/receive timeouts). **Azure**: still scrub sensitive data on the error path — the `Ocp-Apim-Subscription-Key` lives in request headers and must never be logged; the error path logs only `inspect(reason)` from `{:error, %{reason: reason}}`, and `Req`/`Mint` transport-error structs carry just `:reason` (no headers/body), so the key cannot leak.

## Production / deploy

Built with **Nixpacks** (`nixpacks.toml`), deployed via Coolify. Reproduce locally:

```sh
nixpacks build . --name scc-phoenix
docker run --rm -p 4000:4000 --env-file .env.prod-test scc-phoenix
```

Required env vars are documented in `config/runtime.exs`; key ones: `SECRET_KEY_BASE`, `LIVE_SIGNING_SALT`, `ENCRYPTION_KEY`, `TWITCH_CLIENT_ID/SECRET`, `TWITCH_TOKEN_SECRET`, `AZURE_COGNITIVE_KEY`, `DEEPGRAM_TOKEN`, `METRICS_AUTH_TOKEN` (bearer token protecting `/metrics`), and either `DATABASE_URL` (with `USE_SSL=true`) or the `RDS_*` set.

The container entrypoint is `/app/bin/server`, which runs `Release.migrate` then boots Phoenix on `4000`.
