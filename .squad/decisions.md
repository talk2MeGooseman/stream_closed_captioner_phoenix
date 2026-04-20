# Squad Decisions

## Active Decisions

### Pragmatic Programmer Methodologies — Team Standard

**By:** Erik Guzman (via Copilot)
**Date:** 2026-04-21
**Category:** Process & Philosophy

All team members should read and follow *The Pragmatic Programmer* methodologies as core development practices for this project.

**Key Principles:**
- **DRY (Don't Repeat Yourself)** — eliminate duplication in code and logic
- **Fail Fast & Handle Errors Gracefully** — explicit error messaging over silent failures
- **Invest in Tooling** — leverage linting, testing, automation, CI/CD effectively
- **Refactor Ruthlessly** — continuously improve code structure and clarity
- **Know Your Domain** — master Twitch API, Phoenix patterns, Elixir idioms
- **Communicate Clearly** — code should be readable; tests should document behavior
- **Automate Tests** — catch issues early; prioritize test coverage
- **Estimate Carefully** — be realistic about complexity and dependencies

**Impact on Review:** Code reviews evaluate adherence to these principles. PRs that violate DRY, fail to handle errors gracefully, or lack clarity are sent back for refinement.

**Status:** ✅ Adopted as team standard
### 2026-04-19: Twitch extension status polling retries in twitch_controller.js (consolidated)

**By:** Neo, Trinity

**What:**

- `fetchExtensionStatus` in `assets/js/controllers/twitch_controller.js` uses bounded retry behavior for both `extensionInstalled === false` responses and network/request failures.
- Retry ceiling is 10 attempts (constant/value-driven), with exponential backoff using a base delay of 2000ms and a maximum delay cap of 30000ms.
- Retry delay is computed from current attempt state and then attempt count advances, preserving an initial quick retry cadence.
- Request failures are handled explicitly (catch path), with terminal user-visible messaging when attempts are exhausted.
- Timer lifecycle is explicit: pending retry timeout is cleared before scheduling and on controller `disconnect()` to prevent ghost retries.

**Why:**

- Prevent unbounded polling loops and silent Promise rejection paths.
- Avoid timer accumulation and callbacks after controller teardown.
- Preserve successful-path UX while making failure modes explicit and bounded.
- Keep polling reliability logic self-contained in the controller and easy to tune.

### 2026-04-19: Remove dead TMI/TwitchBot code path

**By:** Trinity

**What:**

- Remove unused `twitch_bot.ex` stub.
- Remove `:tmi` dependency and lockfile entry.
- Remove obsolete `:bot` configuration and commented supervisor/function remnants.

**Why:**

- The bot path had been disabled for years with no references.
- Reduces dependency and configuration surface area.
- Keeps supervision and runtime config focused on active components.

### 2026-04-20: Security audit log events via shared Logger + Telemetry contract

**By:** Trinity

**What:**

- Implement security audit events through a shared lightweight module that emits both structured Logger entries and Telemetry events.
- Emit telemetry on `[:stream_closed_captioner_phoenix, :audit_log]` with metadata including `event`, `level`, and contextual non-secret fields.
- Apply the contract to security-relevant flows: bits debit/credit, translation activation, password change/reset (including reset instruction issuance), and OAuth link/unlink plus settings entry points that invoke these actions.
- Enforce metadata redaction for sensitive keys: `access_token`, `refresh_token`, `token`, `password`, `current_password`, `encrypted_password`, `azure_service_key`.

**Why:**

- Provides immediate security observability without introducing migrations or a persistence subsystem.
- Keeps runtime behavior stable while improving incident traceability and testability.
- Standardizes audit semantics across sensitive flows with explicit redaction requirements.

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction
