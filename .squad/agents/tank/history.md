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
