# Project Context

- **Owner:** Erik Guzman
- **Project:** stream_closed_captioner_phoenix — real-time closed captioning for Twitch streamers
- **Stack:** Elixir, Phoenix, PostgreSQL, Absinthe (GraphQL), Phoenix Channels, Phoenix LiveView, Oban, Twitch API (OAuth, JWT, EventSub, Extension), Azure Cognitive Services, Mox, FunWithFlags, Nebulex
- **Created:** 2026-04-19

### Backend Patterns

- **Service mocking:** External services use behaviour modules in app config → `Azure.MockCognitive`, `Twitch.MockExtension`, `Twitch.MockHelix` in tests
- **Encryption:** `EncryptedBinary` Ecto type (AES-256-GCM) for secrets; key from `ENCRYPTION_KEY` env var
- **Timestamps:** All schemas use `timestamps(inserted_at: :created_at)` — column is `created_at`
- **Empty string handling:** Convert `""` → `nil` for nullable secret fields in changesets
- **Translation gating:** `CaptionsPipeline.Translations.maybe_translate/3` — user's own Azure key → direct call; no key → Bits balance deduction
- **Factories:** `insert(:user)` creates user with pre-built `stream_settings` and `bits_balance` — update those, don't insert new ones
- **HTTP calls to Azure:** Use `HTTPoison.post` (not `post!`), pattern-match result, scrub sensitive data before logging

### Caption Pipeline Flow

1. Client sends audio blob or text to `CaptionsChannel` (`captions:USER_ID`)
2. Channel pattern-matches on payload type (`publishFinal`, `publishBlob`, etc.)
3. `CaptionsPipeline` applies: censor → pirate mode → translate
4. Output: `:twitch` → `Absinthe.Subscription.publish/3`; `:zoom` → Zoom API; `:default` → `transcript:1` PubSub

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->
- 2026-04-19: `assets/js/controllers/twitch_controller.js` treats extension-status polling as bounded state (max attempts + exponential backoff + timer cleanup on disconnect + network-error catch), keeps success path immediate when `extensionInstalled` becomes true.
- 2026-04-19: Security audit events use shared `StreamClosedCaptionerPhoenix.AuditLog` — emits Logger entries + Telemetry on `[:stream_closed_captioner_phoenix, :audit_log]`, secret-key redaction before emission.
- 2026-04-19: Audit coverage includes Bits translation activation/debit-credit, Accounts password change/reset + reset-instructions, OAuth link/unlink, User Settings action entry points; tests assert telemetry events directly.
- 2026-04-25: TMI/TwitchBot was fully dead code in runtime (supervisor commented, no callsites/tests). Safe removal includes config+deps+module cleanup and lock pruning (`mix deps.unlock --unused`) to prevent stale dependency drift.
- 2026-04-25: Issue #278 Path A was selected and implemented end-to-end with compile + targeted test verification; decision and risk notes were handed off for canonical merge.
