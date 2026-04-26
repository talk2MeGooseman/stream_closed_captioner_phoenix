# Project Context

- **Owner:** Erik Guzman
- **Project:** stream_closed_captioner_phoenix — real-time closed captioning for Twitch streamers
- **Stack:** Elixir, Phoenix, PostgreSQL, Absinthe (GraphQL), Phoenix Channels, Phoenix LiveView, Oban, Twitch API (OAuth, JWT, EventSub, Extension), Azure Cognitive Services, Mox, FunWithFlags, Nebulex
- **Created:** 2026-04-19

### Frontend Architecture I Work Within

- **LiveView auth:** `session_current_user(session)` from `LiveHelpers` in `mount/3` reads `"user_token"` from session; preload all needed assocs here
- **Flash caveat:** `put_flash` in `live_component` NOT propagate to parent LiveView in Phoenix LiveView 0.19 — verify via DB state in tests
- **Twitch Extension JS:** Browser overlay sends Twitch-signed JWT; server validates via `Twitch.Jwt` in GraphQL `Context` plug; JS polls `me.extensionInstalled` every 2s til true
- **Absinthe subscriptions:** Browser subs to `new_twitch_caption`; server publishes from `CaptionsChannel` via `Absinthe.Subscription.publish/3` keyed by `user.uid`
- **Asset pipeline:** Phoenix static builds under `priv/static/`; JS under `assets/js/`; `mix phx.digest` for prod

### Key Frontend Flows

1. Streamer opens dashboard LiveView → connects socket → starts SpeechRecognition or Deepgram WebSocket
2. Caption text sent to `CaptionsChannel` via Phoenix Channel push
3. Processed caption published via Absinthe Subscription to viewer overlay
4. Viewer Twitch Extension JS gets event → renders caption on stream

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->