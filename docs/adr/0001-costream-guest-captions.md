---
title: "ADR-0001: Co-Streamer Guest Captions via Separate Channel and Subscription"
status: "Accepted"
date: "2026-07-12"
authors: "Erik Guzman (Owner)"
tags: ["architecture", "decision", "captions", "costream", "twitch-extension"]
supersedes: ""
superseded_by: ""
---

# ADR-0001: Co-Streamer Guest Captions via Separate Channel and Subscription

## Status

Accepted

## Context

Streamers co-stream with guests (podcasts, squad streams, interviews), but only
the primary streamer's speech is captioned. Guests' words are invisible to
viewers who rely on captions.

Forces at play:

- **Backwards compatibility is structural, not optional.** Released Twitch
  extension bundles are frozen JavaScript with the `newTwitchCaption` GraphQL
  selection set (`interim`, `final`, `translations`) hardcoded. Whatever
  arrives on that subscription renders as the streamer's own caption line,
  unattributed. Twitch controls version rollout; old bundles stay live for
  weeks or longer.
- **Performance.** The caption pipeline runs per utterance. Translations cost
  money (Azure/Gemini, bits-gated) and add a 3s-timeout async hop; pirate mode
  is cosmetic. Multiplying either by N concurrent guests multiplies cost and
  latency for no product requirement.
- **Trust.** A guest link puts words on someone else's stream. The host must
  keep unilateral, immediate control (mute, kick, global off), and guests must
  not be able to caption to an audience while the host is not even streaming.
- **Low friction.** Podcast guests are often one-off participants without SCC
  accounts; requiring registration or Twitch OAuth would kill adoption.
- **Existing plumbing.** The app already has Phoenix Channels, Absinthe
  subscriptions keyed by Twitch channel id, a presence tracker of actively
  captioning channels (`UserTracker`), a supervised-but-unused Hammer rate
  limiter, FunWithFlags, and two shareable-token precedents
  (`caption_source_token`, the admin local-extension-testing JWT).

## Decision

Add a parallel, slimmer guest caption path rather than extending the existing
one:

- **Per-guest signed links** (`Costream` context, `costream_guests` table).
  The `Phoenix.Token` link carries only the guest id; authorization state
  (revocation, mute, host-assigned display name) lives on the DB row and is
  re-checked on socket connect, channel join, and via live control events —
  so host actions are immediate and tokens never need rotating. No guest
  accounts.
- **Dedicated `CostreamChannel`** (`costream:HOST_ID`) with two roles: guest
  sockets (link-token auth) may publish; the host's user socket joins
  read-only. Guest publishes are rate limited per guest (Hammer, 15/sec),
  gated on the host actively captioning (`UserTracker`), the
  `:costream_captions` feature flag, and a `costream_enabled` kill switch on
  stream settings.
- **Slim pipeline path** `CaptionsPipeline.pipeline_to(:costream, host, msg)`:
  the HOST's censoring settings only — no pirate mode, no translations.
- **Separate GraphQL subscription** `new_costream_caption` (guest id, name,
  interim, final). The existing `new_twitch_caption` payload is untouched, so
  pre-costream extension bundles never receive guest text.
- **Fan-out**: extension subscription + OBS overlay (finals only,
  name-prefixed) + a host monitor PubSub topic feeding the `/users/costream`
  LiveView (live text, connected state, mute/kick).
- **Guest transcription in the guest's browser** via the free Web Speech API
  (Chrome/Edge/Safari), reusing the dashboard's `SpeechRecognitionHandler`.

## Consequences

### Positive

- **POS-001**: Old extension versions are provably unaffected — they cannot
  select fields they don't query, and guest text never travels on their
  subscription. No coordinated release needed between backend and extension.
- **POS-002**: Guest cost scales near-zero: no translation/pirate spend, no
  server-side speech-to-text, censoring is an in-process regex pass. Fan-out
  is bounded by the 4-guest cap and per-guest rate limit.
- **POS-003**: Host trust controls are immediate and cluster-safe: mute/kick
  travel as `Endpoint.broadcast/3` control events intercepted by guest channel
  processes on any node; revocation is a DB flag checked on every verify.
- **POS-004**: Fault tolerant by construction — guests pause automatically
  when the host stops captioning; a crashed guest channel unregisters from the
  tracker; the whole feature can be killed per-host (settings toggle) or
  globally (feature flag) without deploys.
- **POS-005**: Reuses existing primitives (Channels, Absinthe topics keyed by
  Twitch uid, Hammer, FunWithFlags, tracker), keeping new surface area small.

### Negative

- **NEG-001**: Viewers on old extension versions see no guest captions at all
  (chosen over unattributed degradation); full experience requires a new
  extension release and Twitch review.
- **NEG-002**: Guest captions are never translated, so viewers watching a
  translation language get mixed-language output (or hide guests) — a
  deliberate performance trade-off surfaced as a viewer sub-toggle.
- **NEG-003**: Web Speech API limits guests to Chrome/Edge/Safari and
  quality varies by browser; the guest page must warn unsupported browsers.
- **NEG-004**: Each guest publish reads stream settings + flag state
  (mirroring the existing per-message pattern); at the 4-guest cap this
  multiplies that per-utterance DB/cache load.
- **NEG-005**: Anyone holding an unrevoked link can caption while the host is
  live — the trust model is possession + host moderation, not identity.

## Alternatives Considered

### Publish guest text on the existing `new_twitch_caption` subscription

- **ALT-001**: **Description**: Add guest fields to the existing payload
  and/or publish guest events on the same topic, letting old clients degrade.
- **ALT-002**: **Rejection Reason**: Old bundles render whatever arrives in
  `final`/`interim` as the streamer's own words — strangers' unattributed text
  on the host's stream is a trust failure, not graceful degradation.
  Name-prefixing text inside `final` would pollute new clients' data,
  translations, and dedup logic.

### Require guest login (Twitch OAuth or SCC account)

- **ALT-003**: **Description**: Authenticate guests as real users, giving
  verified identity for attribution and abuse handling.
- **ALT-004**: **Rejection Reason**: Kills the one-click podcast-guest flow;
  host-assigned names on per-guest revocable links give equivalent practical
  control (per-guest revoke/mute) without onboarding friction.

### Server-side transcription for guests (Deepgram)

- **ALT-005**: **Description**: Stream guest audio to the server and use the
  existing Deepgram integration for higher-quality transcription.
- **ALT-006**: **Rejection Reason**: The server-global `DEEPGRAM_TOKEN` means
  the platform pays per guest audio-minute, unbounded by anything a host
  controls; audio ingest also adds bandwidth and privacy surface. Browser Web
  Speech is free and matches the host dashboard's default path.

### Do nothing (guests keep talking uncaptioned)

- **ALT-007**: **Description**: Leave co-streams single-speaker.
- **ALT-008**: **Rejection Reason**: Accessibility gap is the product's core
  problem statement; co-streaming is common and repeatedly requested.

## Implementation Notes

- **IMP-001**: Shipped across two repos on branch
  `claude/costreamer-captions-stcu3m`: Phoenix (context, channel, pipeline
  clause, GraphQL, guest page, host LiveView, overlay) and the extension
  (subscription, speaker-tagged queue, viewer toggles).
- **IMP-002**: Rollout: run the migration, enable `:costream_captions` via
  `/feature-flags` (per-actor first, then globally), then release the updated
  extension version. Backend can ship first safely.
- **IMP-003**: Success criteria: guest publishes rejected when host inactive /
  muted / kill-switched (channel test coverage); no change in
  `new_twitch_caption` payload shape; extension bundle diff limited to
  additive subscription + render path.
- **IMP-004**: Monitoring: costream pipeline failures log with guest/host ids;
  rate-limit rejections reply `rate_limited` so the guest UI can back off.

## References

- **REF-001**: `.github/copilot-instructions.md` — "Co-streamer guest
  captions" architecture section.
- **REF-002**: `docs/costream-captions-user-guide.md` — user-facing guide.
- **REF-003**: Related precedent: `caption_source_token` OBS overlay
  (`CaptionSourceLive`) and admin local-extension-testing token minting.
