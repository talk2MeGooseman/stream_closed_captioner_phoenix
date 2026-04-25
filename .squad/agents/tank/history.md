# Project Context

- **Owner:** Erik Guzman
- **Project:** stream_closed_captioner_phoenix — real-time closed captioning for Twitch streamers
- **Stack:** Elixir, Phoenix, PostgreSQL, Absinthe (GraphQL), Phoenix Channels, Phoenix LiveView, Oban, Twitch API (OAuth, JWT, EventSub, Extension), Azure Cognitive Services, Mox, FunWithFlags, Nebulex
- **Created:** 2026-04-19

### Test Infrastructure

| Layer | Use |
|---|---|
| Context/schema logic | `use StreamClosedCaptionerPhoenix.DataCase` |
| Controllers/plugs | `use StreamClosedCaptionerPhoenixWeb.ConnCase` |
| Channels | `use StreamClosedCaptionerPhoenixWeb.ChannelCase` |
| LiveView | `use StreamClosedCaptionerPhoenixWeb.ConnCase` + `import Phoenix.LiveViewTest` |

### Factory Rules

- `insert(:user)` creates user WITH pre-built `stream_settings` and `bits_balance`
- To change those → update existing association via `Repo.update!`, do NOT insert new ones
- Factory module: `StreamClosedCaptionerPhoenix.Factory`

### Mox Setup

- Three mocks: `Azure.MockCognitive`, `Twitch.MockExtension`, `Twitch.MockHelix`
- Defined in `test/test_helper.exs`
- All test files using mocks: `import Mox` + `setup :verify_on_exit!`

### Known Caveats

- `UserTrackerTest` — must NOT use `async: true` (global Phoenix.Tracker state)
- `put_flash` inside `live_component` does not propagate to parent in Phoenix LiveView 0.19
- Oban `testing: :manual` in test env — use `perform_job/2` to run jobs explicitly

### Test Commands

```bash
mix test                          # Full suite
mix test path/to/file.exs         # Single file
mix test path/to/file.exs:42      # Specific test
mix coveralls.html                # Coverage report
```

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### 2026-04-25 — Issue #278 TMI/TwitchBot test coverage audit

- There was no direct test coverage guarding the dead TMI/TwitchBot removal contract.
- Added `test/stream_closed_captioner_phoenix/tmi_removal_test.exs` to lock three safety checks:
	- `:stream_closed_captioner_phoenix` app config does not expose `:bot`.
	- `lib/stream_closed_captioner_phoenix/application.ex` does not reference `TMI.Supervisor` or `bot_config`.
	- `mix.exs` deps list does not include `{:tmi, ...}`.
- Residual coverage gap: this suite intentionally checks `mix.exs` (source of dependency truth) but does not assert lockfile/doc sync; that remains a lightweight manual review point when dependency cleanup touches `mix.lock` or docs.
- 2026-04-25: Targeted issue #278 regression suite validated expected behavior after TMI/TwitchBot removal and is now part of the ongoing guardrail set.
- 2026-04-25: Test assertion normalization: prefer explicit `assert bits_balance == expected_value` over `refute bits_balance` for clarity. Assertion style consistency improves test readability for future maintainers. All 10 tests passing with new coverage for resolver error paths.
