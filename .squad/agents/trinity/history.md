# Project Context

- **Owner:** Erik Guzman
- **Project:** stream_closed_captioner_phoenix — real-time closed captioning for Twitch streamers
- **Stack:** Elixir, Phoenix, PostgreSQL, Absinthe (GraphQL), Phoenix Channels, Phoenix LiveView, Oban, Twitch API (OAuth, JWT, EventSub, Extension), Azure Cognitive Services, Mox, FunWithFlags, Nebulex
- **Created:** 2026-04-19

### Backend Patterns

- **Service mocking:** Ext svcs use behaviour mods in app cfg → `Azure.MockCognitive`, `Twitch.MockExtension`, `Twitch.MockHelix` in tests
- **Encryption:** `EncryptedBinary` Ecto type (AES-256-GCM) for secrets; key from `ENCRYPTION_KEY` env var
- **Timestamps:** All schemas use `timestamps(inserted_at: :created_at)` — col is `created_at`
- **Empty string handling:** Convert `""` → `nil` for nullable secret fields in changesets
- **Translation gating:** `CaptionsPipeline.Translations.maybe_translate/3` — user Azure key → direct call; no key → Bits balance deduct
- **Factories:** `insert(:user)` makes user w/ prebuilt `stream_settings` + `bits_balance` — update those, no new insert
- **HTTP calls to Azure:** Use `HTTPoison.post` (not `post!`), pattern-match result, scrub sensitive data pre-log

### Caption Pipeline Flow

1. Client sends audio blob/text to `CaptionsChannel` (`captions:USER_ID`)
2. Channel pattern-matches on payload type (`publishFinal`, `publishBlob`, etc.)
3. `CaptionsPipeline` applies: censor → pirate mode → translate
4. Output: `:twitch` → `Absinthe.Subscription.publish/3`; `:zoom` → Zoom API; `:default` → `transcript:1` PubSub

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->
- 2026-04-19: `assets/js/controllers/twitch_controller.js` treats ext-status polling as bounded state (max attempts + exp backoff + timer cleanup on disconnect + net-err catch), success path immediate when `extensionInstalled` true.
- 2026-04-19: Security audit events use shared `StreamClosedCaptionerPhoenix.AuditLog` — emits Logger + Telemetry on `[:stream_closed_captioner_phoenix, :audit_log]`, secret-key redact pre-emit.
- 2026-04-19: Audit covers Bits translation activate/debit-credit, Accounts pw change/reset + reset-instructions, OAuth link/unlink, User Settings action entry pts; tests assert telemetry events directly.
- 2026-04-25: TMI/TwitchBot fully dead code at runtime (supervisor commented, no callsites/tests). Safe removal = config+deps+module cleanup + lock prune (`mix deps.unlock --unused`) to stop stale dep drift.
- 2026-04-25: Issue #278 Path A picked + done end-to-end w/ compile + targeted test verify; decision + risk notes handed off for canonical merge.
- 2026-04-25: Resolver err pattern: bang fns (`Accounts.get_user!(id)`) raise `Ecto.NoResultsError` — use `rescue` to catch + convert to GraphQL err tuple, not `case` on nil (dead code). Idiomatic Elixir.