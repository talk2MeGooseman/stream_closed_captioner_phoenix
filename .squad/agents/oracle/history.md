# Project Context

- **Owner:** Erik Guzman
- **Project:** stream_closed_captioner_phoenix — real-time closed captioning for Twitch streamers
- **Stack:** Elixir, Phoenix, PostgreSQL, Absinthe (GraphQL), Phoenix Channels, Phoenix LiveView, Oban, Twitch API (OAuth, JWT, EventSub, Extension), Azure Cognitive Services, Mox, FunWithFlags, Nebulex
- **Created:** 2026-04-19

### Auth Flows

- **Browser sessions:** `UserAuth` plug — `fetch_current_user`, `require_authenticated_user`; token stored in `"user_token"` session key
- **GraphQL/API:** `Context` plug — cookie session token → `context.current_user`; `Authorization: Bearer <token>` → validated as Twitch JWT via `Twitch.Jwt` → `context.decoded_token`
- **Guardian JWT:** `StreamClosedCaptionerPhoenix.Guardian` — subject is integer user `id`; used for `:api_authenticated` REST pipeline
- **EventSub webhooks:** `HTTPSignature` plug validates Twitch HMAC before controller sees request
- **Admin guard:** `:admin_protected` pipeline — requires `user.uid == "120750024"`

### Sensitive Field Rules

**`@derive {Inspect, except: [...]}` must include:**
`:password, :encrypted_password, :azure_service_key, :access_token, :refresh_token`

Keep this list current when adding sensitive fields. Log and crash alerts must not expose any of these.

**`EncryptedBinary` Ecto type (AES-256-GCM):**
- Used for: `azure_service_key`
- Key source: `ENCRYPTION_KEY` env var
- Pattern: apply to any new user-provided secret field

**Empty string → nil:**
User changeset converts `""` → `nil` for `azure_service_key`. Follow for all nullable secret fields.

### Audit Logging Contract

- Function: `StreamClosedCaptionerPhoenix.Audit.log_azure_key_action/3`
- Telemetry event: `[:stream_closed_captioner_phoenix, :audit_log]`
- Redact before emit: `access_token, refresh_token, token, password, current_password, encrypted_password, azure_service_key`
- Operations to log: key created, key updated, key deleted, key used for translation
- Schema timestamp: `timestamps(updated_at: false, inserted_at: :created_at)` for audit log table

### HTTP Scrubbing

Azure HTTP calls use `HTTPoison.post` (not `post!`), pattern-match result. Error path scrubs sensitive data before logging to prevent API key leakage in exception messages.

### Fault Tolerance Patterns

- **Bits race condition:** `BitsBalance` debit uses DB-level check; race condition handled gracefully — translation falls back if insufficient balance
- **Azure fallback:** `maybe_translate/3` returns untranslated caption if Azure call fails rather than crashing pipeline
- **Token expiry:** `Twitch.Oauth.get_users_access_token/1` returns `{:error, :token_expired}` — callers handle gracefully
- **Parser errors:** `Twitch.Parser.parse/1` returns `{:error, map, status_code}` for non-200 and `{:error, %{reason: reason}}` for network errors

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->
- 2026-04-19: Security audit events use shared `StreamClosedCaptionerPhoenix.AuditLog` — emits Logger entries + Telemetry on `[:stream_closed_captioner_phoenix, :audit_log]`, secret-key redaction before emission.
- 2026-04-19: Audit coverage includes Bits translation activation/debit-credit, Accounts password change/reset + reset-instructions, OAuth link/unlink, User Settings action entry points.
- 2026-04-19: `@derive {Inspect, except: [...]}` on User schema covers: `:password, :encrypted_password, :azure_service_key, :access_token, :refresh_token`.
