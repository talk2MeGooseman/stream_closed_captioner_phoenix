# GitHub Copilot Instructions

## What This App Does

Stream Closed Captioner is a Phoenix web app that provides real-time closed captioning for Twitch streamers. Captions are transcribed client-side (via browser SpeechRecognition or Azure Deepgram WebSocket), sent to the server over a Phoenix Channel, processed through a pipeline (censoring, pirate-mode, translation), and then pushed to viewers via a Twitch Extension using Absinthe GraphQL subscriptions.

## Commands

```bash
mix setup              # Install deps, create & migrate DB, build assets
mix test               # Run full test suite (creates DB if needed)
mix test path/to/test_file.exs        # Run a single test file
mix test path/to/test_file.exs:42     # Run test at specific line
mix lint               # Run Credo static analysis
mix security           # Run Sobelow security scan
mix phx.server         # Start dev server
mix routes             # List all routes
mix ecto.reset         # Drop, recreate, and migrate DB
```

Coverage: `mix coveralls.html`

## Architecture

### Caption Flow (the core feature)

1. **Client** → sends audio blob or final/interim text to Phoenix Channel (`captions:USER_ID`)
2. **`CaptionsChannel`** → pattern-matches on payload type (`publishFinal`, `publishBlob`, `zoom.enabled`, `twitch.enabled`)
3. **`CaptionsPipeline`** → applies censoring → pirate mode → translation (via `pipeline_to/3`)
4. **Output destinations:**
   - `:twitch` → publishes via `Absinthe.Subscription` to GraphQL subscription `new_twitch_caption`
   - `:zoom` → sends to Zoom live captions API
   - `:default` → broadcasts on `transcript:1` topic

### Translation / Billing

Translation uses Azure Cognitive Services. Two paths exist in `CaptionsPipeline.Translations.maybe_translate/3`:
- **User has their own Azure key** (`user.azure_service_key`) → calls Azure directly with that key, no bits required
- **No user key** → deducts from Bits balance (500 bits activates a timed debit window); falls back gracefully if balance is too low

### Service Providers (Mox pattern)

External services (`Azure`, `Twitch.Extension`, `Twitch.Helix`) are accessed via behaviour modules resolved at runtime from application config:

```elixir
Azure.api_client()         # → Azure.CognitiveProvider behaviour
Twitch.ext_api_client()    # → Twitch.ExtensionProvider behaviour
Twitch.helix_api_client()  # → Twitch.HelixProvider behaviour
```

In tests, these are swapped for Mox mocks:
- `Azure.MockCognitive`
- `Twitch.MockExtension`
- `Twitch.MockHelix`

### Presence & Activity Tracking

Two parallel systems track active channels:
- **`ActivePresence`** (Phoenix.Presence) — presence state for live channels
- **`UserTracker`** (Phoenix.Tracker) — tracks `last_publish` timestamps to determine if a channel is "actively captioning" (within 300s). Used by `Jobs.SendChatReminder`.

### Caching

`StreamClosedCaptionerPhoenix.Cache` uses Nebulex (local adapter). Functions decorated with `use Nebulex.Caching` and `@decorate cacheable(...)` in contexts like `Accounts` and `Twitch`.

### Feature Flags

`FunWithFlags` (backed by PostgreSQL) gates features. Use `FunWithFlags.enabled?(:flag_name, for: user)`. Admin UI at `/feature-flags`.

## Key Conventions

### Security-sensitive fields

`User` has `@derive {Inspect, except: [...]}` — the list includes `:password`, `:encrypted_password`, `:azure_service_key`, `:access_token`, `:refresh_token`. **Always keep this list up-to-date** when adding sensitive fields; never log these values.

### Encrypted fields

`azure_service_key` uses the custom `EncryptedBinary` Ecto type (AES-256-GCM). Use this type for any new field storing a user-provided secret. The encryption key comes from `ENCRYPTION_KEY` env var.

### Empty strings → nil for secret fields

The `User` changeset converts `""` → `nil` for `azure_service_key`. Follow this pattern for any nullable secret field.

### Audit logging

Sensitive key operations (created/updated/deleted/used) go through `StreamClosedCaptionerPhoenix.Audit.log_azure_key_action/3`. Add audit calls whenever sensitive resources are mutated.

### Timestamps

Schemas use `timestamps(inserted_at: :created_at)` — the column is `created_at`, not `inserted_at`. Audit logs use `timestamps(updated_at: false, inserted_at: :created_at)`.

### HTTP calls to Azure

Use `HTTPoison.post` (not `post!`) and pattern-match the result. The error path scrubs sensitive data before logging to prevent API key leakage in exception messages.

### Query modules

Complex queries live in `*Queries` companion modules (e.g., `UserQueries`, `EventsubSubscriptionQueries`) rather than inline in the context. Use `|> Repo.one()` / `|> Repo.all()` at the context boundary.

## Testing

### Test case modules

| What you're testing | Use |
|---|---|
| Context/schema logic | `use StreamClosedCaptionerPhoenix.DataCase` |
| Controllers/plugs | `use StreamClosedCaptionerPhoenixWeb.ConnCase` |
| Channels | `use StreamClosedCaptionerPhoenixWeb.ChannelCase` |
| LiveView | `use StreamClosedCaptionerPhoenixWeb.ConnCase` + `import Phoenix.LiveViewTest` |

### Factory

`insert(:user)` creates a user **with pre-built** `stream_settings` and `bits_balance` associations. To change those, update the existing associations — do **not** insert new ones alongside the user.

```elixir
user = insert(:user)
# Update the pre-created stream_settings, don't insert a new one:
Repo.update!(StreamSettings.changeset(user.stream_settings, %{language: "es-ES"}))
```

### `UserTracker` tests

`UserTrackerTest` must **not** use `async: true` — it touches global Phoenix.Tracker state. Use `on_exit` with a captured PID to untrack after each test.

### Mox setup

All three mocks (`Azure.MockCognitive`, `Twitch.MockExtension`, `Twitch.MockHelix`) are defined in `test/test_helper.exs`. Add `import Mox` and `setup :verify_on_exit!` in any test that uses them.

### LiveView flash caveat

`put_flash` inside a `live_component` does not propagate to the parent LiveView's flash in Phoenix LiveView 0.19 within the same `render_submit` call. Verify side effects via DB state instead.

## Oban Background Jobs

Oban is configured with two queues: `default` (10 workers) and `events` (10 workers). In tests, Oban is set to `testing: :manual` — jobs don't execute automatically; use `perform_job/2` to run them explicitly.

The only current job is `Jobs.SendChatReminder`, which fires a Twitch chat message if a broadcaster hasn't captioned recently. Pattern to follow when adding new jobs:

```elixir
defmodule StreamClosedCaptionerPhoenix.Jobs.MyJob do
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"key" => value}, errors: errors}) do
    if Enum.any?(errors), do: :cancel, else: do_work(value)
  end
end

# Enqueue (inline example from job file comment):
%{key: "value"} |> MyJob.new(schedule_in: 10) |> Oban.insert()
```

Plugins active in all envs: `Pruner`, `Lifeline` (rescues orphaned jobs), `Reindexer`.

## Admin (Kaffy)

Admin is at `/admin`, protected by the `:admin_protected` pipeline (requires `user.uid == "120750024"`). Each resource that needs an admin view gets a companion `*Admin` module:

- `AnnouncementAdmin` — custom form with richtext field
- `Accounts.EventsubSubscriptionAdmin` — adds a dashboard widget showing live EventSub count
- `Settings.StreamSettingsAdmin` — dashboard widget for users without settings; registered as a `scheduled_task` in Kaffy config
- `Bits.BitsBalanceAdmin`, `BitsBalanceDebitAdmin`, `BitsTransactionAdmin`, `Transcripts.TranscriptAdmin`

**Admin module conventions:**
- `index/1` — defines columns; use `%{value: fn record -> ... end}` for derived/associated values
- `form_fields/1` — use `%{update: :readonly}` to lock fields on edit
- `widgets/2` — return list of `%{type: "tidbit", ...}` maps for dashboard cards
- `search_fields/1` — enables search through associations (e.g., `[user: [:email, :username, :uid]]`)

To put the site in maintenance mode (admins still pass through):
```elixir
StreamClosedCaptionerPhoenixWeb.Maintenance.begin()
StreamClosedCaptionerPhoenixWeb.Maintenance.finish()
```

## Authentication & Authorization

**Browser sessions** use Phoenix session tokens via `UserAuth` plug (`fetch_current_user`, `require_authenticated_user`). The token is stored in `"user_token"` session key.

**GraphQL / API** uses two auth mechanisms in the `Context` plug:
- Cookie session token → sets `context.current_user` (used by browser-originated GraphQL calls)
- `Authorization: Bearer <token>` → validated as a Twitch JWT via `Twitch.Jwt`, sets `context.decoded_token` (used by the Twitch extension)

**Guardian** (`StreamClosedCaptionerPhoenix.Guardian`) handles JWT encoding/decoding for the REST API pipeline (`:api_authenticated`). Subject is the user's integer `id`.

**LiveView auth:** Call `session_current_user(session)` from `LiveHelpers` in `mount/3` — it reads `"user_token"` from the session and resolves the user. Always preload needed associations at this point since LiveView doesn't go through controller plugs.

**Eventsub webhooks** (`/webhooks`) go through the `:webhook` pipeline which validates Twitch HMAC signatures via `HTTPSignature` plug before the controller sees the request.

## GraphQL

Schema entry point: `StreamClosedCaptionerPhoenixWeb.Schema`. Resolvers in `lib/.../resolvers/`, types in `lib/.../schema/`. The `GqlConfig` module assembles the Absinthe plug configuration. All fields get `NewRelic.Absinthe.Middleware` prepended automatically via `middleware/3`. Introspection is restricted in non-dev envs via `Schema.Middleware.AuthorizedIntrospection`. In dev, GraphiQL is available at `/graphiql`.

Subscriptions use `Absinthe.Subscription` (started as a child in `Application`). Published from `CaptionsChannel` via:
```elixir
Absinthe.Subscription.publish(Endpoint, payload, new_twitch_caption: user.uid)
```

## Transcripts

`Transcripts` context manages per-session caption archives. A `Transcript` groups many `Message` records by `session` (a unique string per caption session). The `transcript:1` PubSub topic is used to record live captions when the `:caption_source` feature flag is enabled for the user.

## Environment Variables (key ones)

| Variable | Purpose |
|---|---|
| `ENCRYPTION_KEY` | AES-256-GCM key for `EncryptedBinary` fields |
| `DATABASE_URL` | PostgreSQL connection string |
| `SECRET_KEY_BASE` | Phoenix endpoint secret |
| `TWITCH_CLIENT_ID` / `TWITCH_CLIENT_SECRET` | Twitch OAuth |
| `AZURE_COGNITIVE_KEY` | Server-side Azure key (used when user has no own key) |
| `DEEPGRAM_TOKEN` | API token for Deepgram WebSocket transcription |
