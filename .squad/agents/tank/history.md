# Project Context

- **Owner:** Erik Guzman
- **Project:** stream_closed_captioner_phoenix — real-time closed captioning Twitch streamers
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

- `insert(:user)` make user WITH pre-built `stream_settings` and `bits_balance`
- Change those → update existing association via `Repo.update!`, no insert new
- Factory module: `StreamClosedCaptionerPhoenix.Factory`

### Mox Setup

- Three mocks: `Azure.MockCognitive`, `Twitch.MockExtension`, `Twitch.MockHelix`
- Live in `test/test_helper.exs`
- All test files using mocks: `import Mox` + `setup :verify_on_exit!`

### Known Caveats

- `UserTrackerTest` — no use `async: true` (global Phoenix.Tracker state)
- `put_flash` inside `live_component` no propagate to parent in Phoenix LiveView 0.19
- Oban `testing: :manual` in test env — use `perform_job/2` run jobs explicit

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

- No direct test coverage guard dead TMI/TwitchBot removal contract.
- Add `test/stream_closed_captioner_phoenix/tmi_removal_test.exs` lock three safety checks:
	- `:stream_closed_captioner_phoenix` app config no expose `:bot`.
	- `lib/stream_closed_captioner_phoenix/application.ex` no reference `TMI.Supervisor` or `bot_config`.
	- `mix.exs` deps list no include `{:tmi, ...}`.
- Residual gap: suite check `mix.exs` (dep truth source) but no assert lockfile/doc sync; stay manual review when dep cleanup touch `mix.lock` or docs.
- 2026-04-25: Issue #278 regression suite confirm behavior after TMI/TwitchBot removal, now part of guardrail set.
- 2026-04-25: Assertion style: prefer explicit `assert bits_balance == expected_value` over `refute bits_balance` for clarity. Consistent style help future readers. All 10 tests pass with new coverage for resolver error paths.