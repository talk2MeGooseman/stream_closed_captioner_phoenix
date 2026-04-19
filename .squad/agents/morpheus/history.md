# Project Context

- **Owner:** Erik Guzman
- **Project:** stream_closed_captioner_phoenix — real-time closed captioning platform for Twitch streamers
- **Stack:** Elixir, Phoenix, PostgreSQL, Absinthe (GraphQL), Phoenix Channels, Phoenix LiveView, Oban (background jobs), Twitch API (OAuth, JWT, EventSub, Extension), Azure Cognitive Services (translation), Mox (test mocking), FunWithFlags (feature flags), Nebulex (caching)
- **Created:** 2026-04-19

### Architecture Overview

The app delivers captions from streamer → server → viewers via:
1. Browser SpeechRecognition or Azure Deepgram WebSocket (client-side transcription)
2. Phoenix Channel (`captions:USER_ID`) receives caption payloads
3. `CaptionsPipeline` applies censoring → pirate mode → optional translation
4. Output routes to Twitch Extension (via Absinthe Subscription `new_twitch_caption`), Zoom API, or default PubSub broadcast
5. Translation is gated by Twitch Bits balance (500 bits activates a timed debit window)
6. External services (Azure, Twitch Helix, Twitch Extension) use behaviour/mock pattern for testability

### Key Decisions

- External service calls use behaviour modules resolved at runtime from app config → swapped for Mox mocks in tests
- `EncryptedBinary` Ecto type (AES-256-GCM) used for sensitive fields like `azure_service_key`
- Schemas use `timestamps(inserted_at: :created_at)` — column is `created_at`, not `inserted_at`
- Complex queries live in `*Queries` companion modules, not inline in contexts

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->
