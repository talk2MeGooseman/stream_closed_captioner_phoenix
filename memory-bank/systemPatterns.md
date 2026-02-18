# System Patterns

## Architecture Overview

Stream Closed Captioner Phoenix follows a modular Phoenix architecture with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                         Frontend                            │
│  Browser (Stimulus.js) + Twitch Extension (Viewer Display) │
└──────────────┬──────────────────────────┬──────────────────┘
               │ WebSocket                 │ GraphQL
               ↓                           ↓
┌─────────────────────────────────────────────────────────────┐
│                    Phoenix Framework                         │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Channels   │  │   GraphQL    │  │  LiveView    │      │
│  │  (Real-time)│  │  (Absinthe)  │  │  (Dashboard) │      │
│  └─────────────┘  └──────────────┘  └──────────────┘      │
└──────────────┬──────────────────────────┬──────────────────┘
               │                           │
               ↓                           ↓
┌─────────────────────────────────────────────────────────────┐
│                     Business Logic                           │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │    Contexts      │  │     Services     │                │
│  │ (Domain Logic)   │  │  (External APIs) │                │
│  └──────────────────┘  └──────────────────┘                │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ Captions Pipeline│  │  Background Jobs │                │
│  │ (Processing)     │  │     (Oban)       │                │
│  └──────────────────┘  └──────────────────┘                │
└──────────────┬──────────────────────────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────────────────────────┐
│              Data Layer & External Services                  │
│  ┌──────────┐  ┌──────────┐  ┌─────────┐  ┌─────────┐     │
│  │PostgreSQL│  │  Redis   │  │Deepgram │  │  Azure  │     │
│  │  (Ecto)  │  │ (Cache)  │  │  (STT)  │  │(Translate)│   │
│  └──────────┘  └──────────┘  └─────────┘  └─────────┘     │
└─────────────────────────────────────────────────────────────┘
```

## Key Design Patterns

### 1. Phoenix Contexts
Organize business logic into bounded contexts:
- **Accounts**: User management, authentication
- **Settings**: Stream settings, user preferences
- **Transcripts**: Caption storage and retrieval
- **Bits**: Virtual currency management
- **CaptionsPipeline**: Caption processing workflow

### 2. Service Objects
Encapsulate external API interactions:
- `Twitch` service: Helix API, Extension API
- `Azure.Cognitive` services: Translations
- `DeepgramWebsocket`: Speech-to-text provider

### 3. Pipeline Pattern
`CaptionsPipeline` module implements sequential transformations:
```elixir
CaptionsPayload.new(message)
|> apply_censoring(stream_settings)
|> Translations.maybe_translate(:final, user)
|> apply_pirate_mode(stream_settings)
```

### 4. Real-time Communication
- **Phoenix Channels**: Bidirectional WebSocket for caption streaming
- **GraphQL Subscriptions**: Push updates to Twitch extension viewers
- **PubSub**: Internal broadcast system for real-time events
- **LiveView**: Real-time UI updates without JavaScript

### 5. Background Processing
**Oban** for async jobs:
- Email sending
- Batch processing
- Scheduled tasks
- Retry logic for failed operations

## Component Relationships

### Caption Flow Architecture
```
Browser Mic → Speech Recognition → CaptionsChannel
                                          ↓
                              pipeline_to(:twitch, user, message)
                                          ↓
                              ┌──────────────────────┐
                              │  CaptionsPipeline   │
                              │  - Profanity Filter │
                              │  - Translations     │
                              │  - Pirate Mode      │
                              └──────────────────────┘
                                          ↓
                ┌────────────────────────────────────────┐
                ↓                                        ↓
        Phoenix.PubSub                          Absinthe Subscription
        (Dashboard updates)                     (Twitch Extension)
                ↓                                        ↓
        LiveView Updates                          Viewer Overlay
```

### Authentication Flow
```
User → Ueberauth (Twitch OAuth) → Guardian (JWT) →
Protected Routes/Channels
```

### Data Access Pattern
```
Controller/Channel → Context → Schema/Query → Ecto → PostgreSQL
                              ↓
                           Changeset (Validation)
```

## Key Technical Decisions

### 1. Speech Recognition Strategy
- **Primary**: Browser Web Speech API (free, low-latency, client-side)
- **Alternative**: Deepgram WebSocket (higher accuracy, costs money)
- **Decision**: Feature flag to switch between providers

### 2. Real-time Architecture
- Phoenix Channels for streamer ↔ server communication
- GraphQL subscriptions for server → viewers
- Allows horizontal scaling with distributed PubSub

### 3. Caching Strategy
- **Nebulex**: Application-level cache for computed data
- **Redis**: Session storage and distributed cache
- **ETS**: In-memory cache for hot data
- Cache frequently accessed settings, user data

### 4. Translation Management
- Azure Cognitive Services for translations
- Bits system to monetize and control costs
- Only translate "final" text, not interim
- Cache translation results when possible

### 5. Error Handling
- Supervision trees for process resilience
- Graceful degradation (skip translations if service down)
- Structured error responses with `:ok`/`:error` tuples
- New Relic for monitoring and alerting

## Module Organization

### `lib/stream_closed_captioner_phoenix/`
- `accounts/` - User management
- `bits/` - Virtual currency
- `captions_pipeline/` - Caption processing
- `jobs/` - Background jobs
- `services/` - External API wrappers
- `settings/` - Configuration
- `transcripts/` - Caption history
- `types/` - Custom Ecto types

### `lib/stream_closed_captioner_phoenix_web/`
- `channels/` - WebSocket handlers
- `controllers/` - HTTP endpoints
- `components/` - Reusable UI components
- `live/` - LiveView modules
- `plugs/` - Request pipeline
- `resolvers/` - GraphQL resolvers
- `schema/` - GraphQL schema

## Scalability Considerations

### Current Approach
- Single server deployment (Elastic Beanstalk)
- Redis for distributed caching
- Oban for queue processing
- Database connection pooling

### Future Scaling Options
- Horizontal scaling with libcluster + EC2 discovery
- Dedicated worker nodes for Oban
- Read replicas for database
- CDN for static assets
- Multi-region deployment for global latency
