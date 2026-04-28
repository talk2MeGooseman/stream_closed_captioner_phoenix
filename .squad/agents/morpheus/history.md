# Project Context

- **Owner:** Erik Guzman
- **Project:** stream_closed_captioner_phoenix — realtime CC 4 Twitch streamers
- **Stack:** Elixir, Phoenix, PostgreSQL, Absinthe (GraphQL), Phoenix Channels, Phoenix LiveView, Oban, Twitch API (OAuth, JWT, EventSub, Extension), Azure Cognitive Services, Mox, FunWithFlags, Nebulex
- **Created:** 2026-04-19

### Architecture Overview

App send caps streamer → server → viewers:
1. Browser SpeechRecognition or Azure Deepgram WebSocket (client-side transcription)
2. Phoenix Channel (`captions:USER_ID`) get cap payload
3. `CaptionsPipeline` do: censor → pirate mode → maybe translate
4. Out: Twitch Extension (Absinthe Subscription `new_twitch_caption`), Zoom API, or default PubSub
5. Translate gated by Twitch Bits bal (500 bits = timed debit window on)
6. External svc (Azure, Twitch Helix, Extension) use behaviour/mock 4 testable

### Key Decisions

- External svc calls use behaviour mods resolved runtime from app config → Mox mocks in tests
- `EncryptedBinary` Ecto type (AES-256-GCM) 4 secret fields like `azure_service_key`
- Schemas use `timestamps(inserted_at: :created_at)` — col is `created_at`
- Big queries go in `*Queries` sibling mods, not inline in contexts

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### 2026-07-22 — Coolify Deploy Secret Leak Analysis

- **Dockerfile is clean.** All secrets read at runtime via `System.get_env` in `config/runtime.exs`. No `ARG`-based secrets in our Dockerfile.
- **Coolify injects ALL env vars as `--build-arg` by default.** This bakes secrets into image layer metadata even when Dockerfile never references them. Fix: separate build vars from runtime vars in Coolify UI.
- **Dead bot config persists.** `runtime.exs` lines 117-123 still reference `TwitchBot` and `TWITCH_CHAT_OAUTH` despite TMI removal decision (2026-04-25). `docs/coolify-migration.md` still lists `TWITCH_CHAT_OAUTH` as required. Both need cleanup.
- **Key architectural principle confirmed:** Runtime config via `config/runtime.exs` + `System.get_env` is the correct pattern for containerized Elixir. Build-time secrets should never be needed for this app.