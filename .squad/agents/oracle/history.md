# Project Context

- **Owner:** Erik Guzman
- **Project:** stream_closed_captioner_phoenix — real-time closed captioning platform for Twitch streamers
- **Stack:** Elixir, Phoenix, PostgreSQL, Absinthe (GraphQL), Phoenix Channels, Phoenix LiveView, Oban (background jobs), Twitch API (OAuth, JWT, EventSub, Extension), Azure Cognitive Services (translation), Mox (test mocking), FunWithFlags (feature flags), Nebulex (caching)
- **Created:** 2026-04-19

### Security Architecture I Guard

**Authentication flows:**
- Browser sessions: `UserAuth` plug → `fetch_current_user` / `require_authenticated_user`; token in `"user_token"` session key
- GraphQL/API: cookie session token → `context.current_user`; or `Authorization: Bearer <token>` → Twitch JWT → `context.decoded_token`
- Guardian: `StreamClosedCaptionerPhoenix.Guardian` encodes/decodes JWTs; subject is user integer `id`
- EventSub webhooks: `HTTPSignature` plug validates Twitch HMAC before controller sees the request

**Sensitive field rules:**
- `User` schema has `@derive {Inspect, except: [...]}` — currently covers `:password`, `:encrypted_password`, `:azure_service_key`, `:access_token`, `:refresh_token`
- NEW sensitive fields must be added to this list immediately
- `azure_service_key` uses `EncryptedBinary` Ecto type (AES-256-GCM)
- Empty strings must convert to `nil` for nullable secret fields

**Audit logging:**
- `StreamClosedCaptionerPhoenix.Audit.log_azure_key_action/3` for Azure key mutations
- Pattern: audit log call on every create/update/delete/use of sensitive resources

**HTTP error scrubbing:**
- `HTTPoison.post` (not `post!`) for Azure calls
- Error paths must scrub sensitive data before logging — never log raw API keys or tokens

**Admin protection:**
- Admin pipeline: `:admin_protected` requires `user.uid == "120750024"`
- Maintenance mode: `StreamClosedCaptionerPhoenixWeb.Maintenance.begin/0` / `finish/0`

### Fault Tolerance Concerns

- Translation deducts from Bits balance — must handle race conditions and negative balance edge cases
- Azure Cognitive Services calls must fail gracefully (fallback to no translation, not crash)
- Twitch OAuth token expiry: `Twitch.Oauth.get_users_access_token/1` returns `{:error, :token_expired}` — callers must handle this
- `Twitch.Parser.parse/1` returns `{:error, map, status_code}` for non-200 HTTP — always pattern match on this

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->
