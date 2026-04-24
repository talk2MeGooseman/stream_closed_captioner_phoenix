# Decisions

Active decisions shaping project. New → `.squad/decisions/inbox/`. Scribe merges.

---

## 2026-04-21 — Pragmatic Programmer Methodologies as Team Standard

**By:** Erik Guzman (Owner) | **Status:** Active

Follow Pragmatic Programmer methodologies. Applies to all agents + contributors.

- DRY
- Orthogonality — decouple components
- Tracer bullets for dev
- Design by Contract
- Write code that writes code when appropriate
- Build in testing from start

---

## 2026-04-19 — Twitch Extension Polling Bounded Retry Contract

**By:** Neo, Trinity | **Status:** Active

`assets/js/controllers/twitch_controller.js` polling uses bounded retry:

- Max attempts: 10
- Base delay: 2000ms
- Delay cap: 30000ms
- Strategy: exponential backoff (`Math.min(base * 2^attempt, cap)`)
- On disconnect: explicit timer cleanup (no dangling intervals)
- Network errors: caught + handled (no unhandled rejections)
- Success: immediate proceed when `extensionInstalled` true, no extra delay

Unbounded polling caused socket thrash + unhandled rejections in prod. Bounded contract = predictable.

---

## 2026-04-19 — Remove Dead TMI/TwitchBot Code Path

**By:** Trinity | **Status:** Active

Remove dead bot/TMI code:

- Delete `lib/stream_closed_captioner_phoenix/services/twitch/twitch_bot.ex`
- Remove `:tmi` from deps in `mix.exs`
- Remove `:bot` config from `config/`

TMI deprecated, code unreachable. Dead code = maintenance burden + confusion.

---

## 2026-04-20 — Security Audit Log via Shared Logger + Telemetry Contract

**By:** Trinity | **Status:** Active

Security-sensitive mutations emit audit events via `StreamClosedCaptionerPhoenix.AuditLog`:

- Emit on: `[:stream_closed_captioner_phoenix, :audit_log]`
- Logger level: `:info`
- Redact before emit: `access_token, refresh_token, token, password, current_password, encrypted_password, azure_service_key`

Covered: key create/update/delete/use, Bits translation activate/debit/credit, password change/reset, OAuth link/unlink, User Settings mutations.

Tests assert telemetry events via `Telemetry.attach` in test setup.

Centralized contract = consistent audit coverage. Telemetry decouples log sink from event emission.
