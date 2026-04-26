# Project Context

- **Owner:** Erik Guzman
- **Project:** stream_closed_captioner_phoenix — real-time closed captioning for Twitch streamers
- **Stack:** Elixir, Phoenix, PostgreSQL, Absinthe (GraphQL), Phoenix Channels, Phoenix LiveView, Oban, Twitch API (OAuth, JWT, EventSub, Extension), Azure Cognitive Services, Mox, FunWithFlags, Nebulex
- **Created:** 2026-04-19

### Architecture Overview

App delivers captions from streamer → server → viewers:
1. Browser SpeechRecognition or Azure Deepgram WebSocket (client-side transcription)
2. Phoenix Channel (`captions:USER_ID`) receives caption payloads
3. `CaptionsPipeline` applies: censor → pirate mode → optional translation
4. Output: Twitch Extension (Absinthe Subscription `new_twitch_caption`), Zoom API, or default PubSub
5. Translation gated by Twitch Bits balance (500 bits activates timed debit window)
6. External services (Azure, Twitch Helix, Extension) use behaviour/mock pattern for testability

### Key Decisions

- External service calls use behaviour modules resolved at runtime from app config → Mox mocks in tests
- `EncryptedBinary` Ecto type (AES-256-GCM) for sensitive fields like `azure_service_key`
- Schemas use `timestamps(inserted_at: :created_at)` — column is `created_at`
- Complex queries in `*Queries` companion modules, not inline in contexts

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->
