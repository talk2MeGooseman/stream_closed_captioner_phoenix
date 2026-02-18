# Technical Context

## Technology Stack

### Backend
- **Elixir**: 1.16+ (functional, concurrent, fault-tolerant)
- **Phoenix Framework**: 1.7.7 (web framework)
- **Ecto**: 3.4+ (database wrapper and query DSL)
- **PostgreSQL**: Primary data store
- **Absinthe**: 1.7+ (GraphQL server)
- **Oban**: 2.13+ (background job processing)

### Frontend
- **Stimulus.js**: 3.x (JavaScript framework for progressive enhancement)
- **Tailwind CSS**: 3.x (utility-first CSS)
- **Phoenix LiveView**: 0.19+ (real-time server-rendered UI)
- **esbuild**: Asset bundling
- **Alpine.js**: Minimal for component interactivity

### Real-time & Communication
- **Phoenix Channels**: WebSocket communication
- **Phoenix PubSub**: Message broadcasting
- **Redis**: PubSub backend and caching
- **WebSocket**: Direct client connections

### External Services
- **Twitch Helix API**: User data, stream status
- **Twitch Extension API**: Caption delivery to viewers
- **Deepgram**: Speech-to-text (alternative provider)
- **Azure Cognitive Services**: Text translation
- **OBS WebSocket**: OBS Studio integration
- **Zoom API**: Zoom meeting captions

### Infrastructure & DevOps
- **Docker**: Containerization (Dockerfile, Dockerfile.prod)
- **AWS Elastic Beanstalk**: Deployment platform
- **AWS EC2**: Server instances
- **Redis**: Caching and session storage
- **New Relic**: APM and monitoring
- **OpenTelemetry**: Distributed tracing

### Development Tools
- **Mix**: Build tool and task runner
- **ExUnit**: Testing framework
- **ExMachina**: Test factories
- **Credo**: Static code analysis
- **Sobelow**: Security analysis
- **Mock/Mox**: Test mocking

## Development Setup

### Prerequisites
```bash
# Required versions
elixir: ~> 1.16
erlang: 25+
node: 18+ (see .nvmrc)
postgresql: 14+
redis: 6+
```

### Installation
```bash
# Clone repository
git clone https://github.com/talk2MeGooseman/stream_closed_captioner_phoenix.git
cd stream_closed_captioner_phoenix

# Install dependencies
mix deps.get
cd assets && npm install && cd ..

# Setup database
mix ecto.setup

# Start server
mix phx.server
```

### Environment Variables
Required configuration (stored in `.env` or deployment environment):

```bash
# Database
DATABASE_URL=postgresql://user:pass@localhost/db_name

# Twitch Integration
TWITCH_CLIENT_ID=your_client_id
TWITCH_CLIENT_SECRET=your_client_secret
TWITCH_EXTENSION_SECRET=your_extension_secret

# External Services
AZURE_TRANSLATOR_KEY=your_azure_key
AZURE_TRANSLATOR_REGION=eastus
DEEPGRAM_API_KEY=your_deepgram_key

# Application
SECRET_KEY_BASE=generate_with_mix_phx_gen_secret
PHX_HOST=your_domain.com
PORT=4000

# Redis
REDIS_URL=redis://localhost:6379

# New Relic (optional)
NEW_RELIC_APP_NAME=StreamClosedCaptioner
NEW_RELIC_LICENSE_KEY=your_license_key
```

## Project Structure

```
stream_closed_captioner_phoenix/
├── assets/                    # Frontend assets
│   ├── css/                  # Stylesheets (Tailwind)
│   ├── js/                   # JavaScript (Stimulus controllers)
│   │   ├── controllers/      # Stimulus controllers
│   │   ├── channels/         # Phoenix Channel clients
│   │   └── service/          # API clients, utilities
│   └── static/               # Static files (images, fonts)
├── config/                    # Application configuration
│   ├── config.exs            # Base config
│   ├── dev.exs               # Development config
│   ├── prod.exs              # Production config
│   ├── runtime.exs           # Runtime config (env vars)
│   └── test.exs              # Test config
├── lib/
│   ├── stream_closed_captioner_phoenix/     # Business logic
│   │   ├── accounts/         # User management
│   │   ├── bits/             # Virtual currency
│   │   ├── captions_pipeline/# Caption processing
│   │   ├── jobs/             # Background jobs
│   │   ├── services/         # External API wrappers
│   │   ├── settings/         # User preferences
│   │   ├── transcripts/      # Caption history
│   │   └── types/            # Custom Ecto types
│   └── stream_closed_captioner_phoenix_web/ # Web layer
│       ├── channels/         # WebSocket handlers
│       ├── components/       # Reusable components
│       ├── controllers/      # HTTP controllers
│       ├── live/             # LiveView modules
│       ├── plugs/            # Custom plugs
│       ├── resolvers/        # GraphQL resolvers
│       └── schema/           # GraphQL schemas
├── priv/
│   ├── repo/
│   │   ├── migrations/       # Database migrations
│   │   └── seeds.exs         # Seed data
│   └── static/               # Compiled assets
├── test/                      # Test files
│   ├── support/              # Test helpers, factories
│   └── *_test.exs            # Test modules
├── .formatter.exs            # Code formatter config
├── .credo.exs                # Credo config
├── mix.exs                   # Project definition
└── Dockerfile                # Container definition
```

## Key Dependencies

### Production Dependencies
```elixir
# Core
{:phoenix, "~> 1.7.7"}
{:phoenix_ecto, "~> 4.4"}
{:ecto_sql, "~> 3.4"}
{:postgrex, ">= 0.0.0"}

# Real-time
{:phoenix_live_view, "~> 0.19.0"}
{:phoenix_pubsub_redis, "~> 3.0"}

# GraphQL
{:absinthe, "~> 1.7"}
{:absinthe_phoenix, "~> 2.0"}
{:absinthe_plug, "~> 1.5"}

# Background Jobs
{:oban, "~> 2.13"}

# Authentication
{:guardian, "~> 2.0"}
{:ueberauth, "~> 0.10"}
{:ueberauth_twitch, "~> 0.2.0"}
{:bcrypt_elixir, "~> 3.0"}

# Caching
{:nebulex, "~> 2.5"}
{:cachex, "~> 3.4"}

# External APIs
{:hackney, "~> 1.9"}
{:httpoison, "~> 1.8"}
{:neuron, "~> 5.0"}  # GraphQL client

# Monitoring
{:new_relic_agent, "~> 1.30"}
{:telemetry_metrics, "~> 0.6"}
{:opentelemetry, "~> 1.0"}
```

### Development Dependencies
```elixir
{:phoenix_live_reload, "~> 1.2", only: :dev}
{:credo, "~> 1.7", only: [:dev, :test]}
{:sobelow, "~> 0.11", only: :dev}
{:ex_machina, "~> 2.7.0"}
{:mock, "~> 0.3.0", only: :test}
{:mox, "~> 1.0.0", only: :test}
{:bypass, "~> 2.1.0"}
```

## Testing Strategy

### Test Structure
- **Unit Tests**: Contexts, schemas, pipelines
- **Integration Tests**: Channels, controllers, GraphQL
- **Feature Tests**: LiveView end-to-end flows

### Running Tests
```bash
# All tests
mix test

# Watch mode
mix test.watch

# Specific file
mix test test/stream_closed_captioner_phoenix/captions_pipeline_test.exs

# With coverage
mix test --cover
```

### Test Factories
Using ExMachina for test data:
```elixir
# test/support/factory.ex
def user_factory do
  %User{
    email: sequence(:email, &"user#{&1}@example.com"),
    provider: "twitch",
    uid: sequence(:uid, &"twitch_#{&1}")
  }
end
```

## Common Development Tasks

### Database
```bash
mix ecto.create          # Create database
mix ecto.migrate         # Run migrations
mix ecto.rollback        # Rollback last migration
mix ecto.reset           # Drop, create, migrate
mix ecto.gen.migration   # Generate migration
```

### Phoenix
```bash
mix phx.server           # Start server
iex -S mix phx.server    # Start with IEx console
mix phx.routes           # List all routes
mix phx.gen.context      # Generate context
mix phx.gen.live         # Generate LiveView
```

### Code Quality
```bash
mix format               # Format code
mix credo                # Run linter
mix sobelow              # Security analysis
```

### Deployment
```bash
mix assets.deploy        # Compile production assets
mix release              # Build release
mix ecto.migrate         # Run migrations in production
```

## Known Technical Constraints

1. **Browser Speech API**: Chrome/Edge only, requires HTTPS
2. **Deepgram**: Costs per usage, requires WebSocket connection
3. **Azure Translations**: Rate limits, requires active subscription
4. **Twitch Extension**: Review process, frequent updates break things
5. **Single Server**: Current deployment on single AWS EB instance
6. **Redis Dependency**: Required for channels and caching

## Performance Considerations

- Caption latency target: < 2 seconds
- Database queries: Use indexes, preload associations
- Caching: Aggressive caching of settings, translations
- Connection pooling: Default 10 DB connections
- Real-time scaling: Redis PubSub for multi-node support
