# Decisions

Active decisions shape proj. New → `.squad/decisions/inbox/`. Scribe merge.

---

## 2026-04-21 — Pragmatic Programmer Methodologies as Team Standard

**By:** Erik Guzman (Owner) | **Status:** Active

Follow Pragmatic Programmer ways. Apply all agents + contributors.

- DRY
- Orthogonality — decouple parts
- Tracer bullets for dev
- Design by Contract
- Write code that write code when fit
- Build testing from start

---

## 2026-04-19 — Twitch Extension Polling Bounded Retry Contract

**By:** Neo, Trinity | **Status:** Active

`assets/js/controllers/twitch_controller.js` poll use bounded retry:

- Max attempts: 10
- Base delay: 2000ms
- Delay cap: 30000ms
- Strategy: exponential backoff (`Math.min(base * 2^attempt, cap)`)
- On disconnect: explicit timer cleanup (no dangling intervals)
- Network errors: caught + handled (no unhandled rejections)
- Success: go now when `extensionInstalled` true, no extra delay

Unbounded poll = socket thrash + unhandled rejections in prod. Bounded = predictable.

---

## 2026-04-19 — Remove Dead TMI/TwitchBot Code Path

**By:** Trinity | **Status:** Active

Kill dead bot/TMI code:

- Delete `lib/stream_closed_captioner_phoenix/services/twitch/twitch_bot.ex`
- Drop `:tmi` from deps in `mix.exs`
- Drop `:bot` config from `config/`

TMI dead, code unreachable. Dead code = burden + confusion.

---

## 2026-04-20 — Security Audit Log via Shared Logger + Telemetry Contract

**By:** Trinity | **Status:** Active

Security mutations emit audit via `StreamClosedCaptionerPhoenix.AuditLog`:

- Emit on: `[:stream_closed_captioner_phoenix, :audit_log]`
- Logger level: `:info`
- Redact before emit: `access_token, refresh_token, token, password, current_password, encrypted_password, azure_service_key`

Cover: key create/update/delete/use, Bits translation activate/debit/credit, password change/reset, OAuth link/unlink, User Settings mutations.

Tests assert telemetry via `Telemetry.attach` in test setup.

Central contract = consistent audit. Telemetry split log sink from emit.

---

## 2025-01-31 — Local PostgreSQL via Docker Compose

**By:** Trinity | **Status:** Active

Add root `docker-compose.yml` for local PostgreSQL, standard DB password dev/test.

- Base image: `postgres:15-alpine` (pinned major + light)
- Dev/test password: `postgres`
- No `.env.example` need (no env interpolation)

Why: predictable DB boot, less setup friction, same test/dev creds.

---

## 2026-04-25 — Issue #278 Path A Execution: Remove Dead TMI/TwitchBot Path

**By:** Trinity | **Status:** Active

Issue #278 pick Path A, kill dead Twitch bot/TMI code.

- Killed `lib/stream_closed_captioner_phoenix/services/twitch_bot.ex`
- Killed `:tmi` dep from `mix.exs`
- Killed stale bot runtime/config refs
- Pruned unused lock entries via deps unlock
- Verify w/ compile + targeted tests

Why: TMI unreachable/dead, grew maintenance/audit noise.

---

## 2026-04-25 — Issue #278 Security/SRE Risk Gate for TMI Removal

**By:** Oracle (Security/SRE) | **Status:** Active

Go Path A removal w/ safeguards after risk check.

- No live runtime wiring to TMI supervisor seen
- Leftover `use TMI` module need delete to dodge compile break when `:tmi` gone
- Stale `TWITCH_CHAT_OAUTH` in operator docs need kill
- Reminder delivery via extension chat still good per job tests

Need safeguards:

1. Kill all TMI-dep modules.
2. Kill stale `TWITCH_CHAT_OAUTH` doc refs.
3. Verify compile + reminder-job tests in CI for this set.
4. Keep lockfile dep hygiene matched to source deps.

Verdict: no block after orphan cleanup; go removal.

---

## 2026-04-26 — Code Review Gate Standing Directive

**By:** Erik Guzman (User) | **Status:** Active

Always conduct code review after agent work complete. No agent output considered done until separate reviewer reviewed it.

User req. Enforce via process.

---

## 2026-04-26 — Split Bits God-Context into Sub-Contexts

**By:** Trinity | **Status:** Active

Issue #287, branch `squad/287-bits-context-split`.

Split `lib/stream_closed_captioner_phoenix/bits.ex` (507 lines: balance/debit/transaction CRUD + workflows) into three focused modules:

| Module | Responsibility |
|---|---|
| `Bits.Balance` | Balance CRUD + Nebulex cache |
| `Bits.Debit` | Debit CRUD + `activate_translations_for/1` |
| `Bits.Transaction` | Transaction CRUD + `process_bits_transaction/2` |

`Bits` becomes thin `defdelegate` facade. All callers (`Bits.get_bits_balance!`, etc.) work unchanged.

### Broadcast-outside-transaction fix

Original `activate_translations_for/1` + `process_bits_transaction/2` had `Ecto.Multi.run(:broadcast, ...)` calling `Endpoint.broadcast` inside transaction—fires before `COMMIT`, phantom rollback updates to clients.

**Fix:** Removed `:broadcast`/`:publish_activity` Multi steps. Now call `Endpoint.broadcast` in `case` block after `Repo.transaction()` returns `{:ok, _}`.

### Cross-context calls inside Multi

`Bits.Debit.activate_translations_for/1` + `Bits.Transaction.process_bits_transaction/2` both call `Bits.Balance.update_bits_balance/2` inside Multi step. OK—pure DB op on same conn, not web-layer side-effect.

### Cache cross-invalidation preserved

`update_bits_balance/2` evicts `{BitsBalance, user_id}` + `{BitsBalanceDebit, user_id}`. `create_bits_balance_debit/2` evicts both. All 5 cache-behavior tests pass.

### defdelegate for default-arg functions

Facade declares two explicit delegations (1-arity + 2-arity) instead `\\` syntax on `defdelegate` to avoid compiler edge cases.

### Trade-offs accepted

- `audit_failure_reason/1` duplicated as 4-line private helper in both `Bits.Debit` + `Bits.Transaction`. Extracting to shared module = overhead disproportionate to size.
- `create_bits_balance_debit/2` called inside `activate_translations_for` Multi means `@decorate cache_evict` + audit log run inside transaction, fire even on rollback. Matches original, acceptable.

---

## 2026-04-26 — Caveman Communication Standing Directive

**By:** Erik Guzman (User) | **Status:** Active

All squad agents MUST communicate caveman mode. Ultra-compressed speak: drop articles/filler/hedging. Fragments OK. Technical terms/code/URLs/paths preserved. Cuts token ~75%.

User req. Enforce via skill invoke.