# Project Context

- **Owner:** Erik Guzman
- **Project:** stream_closed_captioner_phoenix — real-time closed captioning fer Twitch streamers
- **Stack:** Elixir, Phoenix, PostgreSQL, Absinthe (GraphQL), Phoenix Channels, Phoenix LiveView, Oban, Twitch API (OAuth, JWT, EventSub, Extension), Azure Cognitive Services, Mox, FunWithFlags, Nebulex
- **Created:** 2026-04-19

### Auth Flows

- **Browser sessions:** `UserAuth` plug — `fetch_current_user`, `require_authenticated_user`; token in `"user_token"` session key
- **GraphQL/API:** `Context` plug — cookie session token → `context.current_user`; `Authorization: Bearer <token>` → validated as Twitch JWT via `Twitch.Jwt` → `context.decoded_token`
- **Guardian JWT:** `StreamClosedCaptionerPhoenix.Guardian` — subject is integer user `id`; used fer `:api_authenticated` REST pipeline
- **EventSub webhooks:** `HTTPSignature` plug check Twitch HMAC before controller see request
- **Admin guard:** `:admin_protected` pipeline — need `user.uid == "120750024"`

### Sensitive Field Rules

**`@derive {Inspect, except: [...]}` must include:**
`:password, :encrypted_password, :azure_service_key, :access_token, :refresh_token`

Keep list current when add new sensitive field. Log + crash alert no expose any.

**`EncryptedBinary` Ecto type (AES-256-GCM):**
- Used fer: `azure_service_key`
- Key source: `ENCRYPTION_KEY` env var
- Pattern: apply to any new user secret field

**Empty string → nil:**
User changeset turn `""` → `nil` fer `azure_service_key`. Do same fer all nullable secret field.

### Audit Logging Contract

- Function: `StreamClosedCaptionerPhoenix.Audit.log_azure_key_action/3`
- Telemetry event: `[:stream_closed_captioner_phoenix, :audit_log]`
- Redact before emit: `access_token, refresh_token, token, password, current_password, encrypted_password, azure_service_key`
- Ops to log: key created, key updated, key deleted, key used fer translation
- Schema timestamp: `timestamps(updated_at: false, inserted_at: :created_at)` fer audit log table

### HTTP Scrubbing

Azure HTTP call use `HTTPoison.post` (not `post!`), pattern-match result. Error path scrub sensitive data before log to stop API key leak in exception message.

### Fault Tolerance Patterns

- **Bits race condition:** `BitsBalance` debit use DB-level check; race handle clean — translation fall back if balance low
- **Azure fallback:** `maybe_translate/3` give back untranslated caption if Azure call fail, no crash pipeline
- **Token expiry:** `Twitch.Oauth.get_users_access_token/1` give back `{:error, :token_expired}` — callers handle clean
- **Parser errors:** `Twitch.Parser.parse/1` give back `{:error, map, status_code}` fer non-200 and `{:error, %{reason: reason}}` fer network error

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->
- 2026-04-19: Security audit event use shared `StreamClosedCaptionerPhoenix.AuditLog` — emit Logger entry + Telemetry on `[:stream_closed_captioner_phoenix, :audit_log]`, secret-key redact before emit.
- 2026-04-19: Audit cover Bits translation activate/debit-credit, Accounts password change/reset + reset-instructions, OAuth link/unlink, User Settings action entry point.
- 2026-04-19: `@derive {Inspect, except: [...]}` on User schema cover: `:password, :encrypted_password, :azure_service_key, :access_token, :refresh_token`.
- 2026-04-25: Leftover `lib/.../services/twitch_bot.ex` (`use TMI`) can break compile when `:tmi` gone, even if bot supervisor/config wiring already gone; full remove must delete orphan module + stale env var doc.
- 2026-04-25: Issue #278 risk pass confirm Path A safe after orphan cleanup; stale `TWITCH_CHAT_OAUTH` doc mention gone and compile/reminder-job check pass.
- 2026-04-26: Phoenix release Dockerfile need zero secrets at build time. `config/runtime.exs` load all secrets via `System.get_env/1` at container start, not at `mix compile` or `mix release`. ARG/ENV secrets in Dockerfile persist in image layer metadata, extractable via `docker history`. Coolify correct pattern: inject secrets as runtime env vars, never ARG/ENV in Dockerfile.