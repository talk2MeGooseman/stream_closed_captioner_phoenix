# Project Context

- **Owner:** Erik Guzman
- **Project:** stream_closed_captioner_phoenix — real-time closed captioning platform for Twitch streamers
- **Stack:** Elixir, Phoenix, PostgreSQL, Absinthe (GraphQL), Phoenix Channels, Phoenix LiveView, Oban (background jobs), Twitch API (OAuth, JWT, EventSub, Extension), Azure Cognitive Services (translation), Mox (test mocking), FunWithFlags (feature flags), Nebulex (caching)
- **Created:** 2026-04-19

### Frontend Architecture I Work Within

- **LiveView auth:** `session_current_user(session)` from `LiveHelpers` in `mount/3` reads `"user_token"` from session; preload all needed associations here
- **Flash caveat:** `put_flash` inside a `live_component` does NOT propagate to parent LiveView in Phoenix LiveView 0.19 — verify side effects via DB state in tests
- **Twitch Extension JS:** The browser overlay sends a Twitch-signed JWT; the server validates it via `Twitch.Jwt` in the GraphQL `Context` plug; the JS client polls `me.extensionInstalled` GraphQL field every 2s until true
- **Absinthe subscriptions:** Browser subscribes to `new_twitch_caption` subscription; server publishes from `CaptionsChannel` via `Absinthe.Subscription.publish/3` with topic keyed by `user.uid`
- **Asset pipeline:** Phoenix static builds under `priv/static/`; JS under `assets/js/`; compiled with `mix phx.digest` for production

### Key Frontend Flows

1. Streamer opens dashboard LiveView → connects socket → starts SpeechRecognition or Deepgram WebSocket
2. Caption text sent to `CaptionsChannel` via Phoenix Channel push
3. Processed caption published via Absinthe Subscription to viewer overlay
4. Viewer's Twitch Extension JS receives subscription event → renders caption on stream

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->
