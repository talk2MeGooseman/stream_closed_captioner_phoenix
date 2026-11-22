# Active Context

## Current Focus
Co-streamer guest captions shipped on branch `claude/costreamer-captions-stcu3m`
(2026-07-12), pending rollout: run migration → enable `:costream_captions`
flag → release updated extension version.

## Recent Changes
- **Co-streamer guest captions** (2026-07-12): `Costream` context +
  `costream_guests` table (per-guest signed links, host-assigned names,
  revoke/mute state on the row); `CostreamChannel` (`costream:HOST_ID`,
  per-guest Hammer rate limit, gated on host-active + flag + kill switch);
  slim `pipeline_to(:costream, ...)` (host censoring only, no
  pirate/translate); separate `new_costream_caption` GraphQL subscription
  (old extension bundles untouched by design); public guest page at
  `/costream/:token` (Web Speech API); host monitor LiveView at
  `/users/costream` (live text, mute/kick via intercepted broadcasts);
  OBS overlay renders guest finals name-prefixed. ADR:
  `docs/adr/0001-costream-guest-captions.md`. User guide draft:
  `docs/costream-captions-user-guide.md`.
- Created Elixir/Phoenix instruction file with comprehensive coding guidelines
- Establishing memory bank structure for project knowledge
- Documenting system architecture and patterns

## Active Work Areas

### Documentation Enhancement
- Creating memory bank files to preserve project knowledge
- Building custom instruction files for GitHub Copilot
- Establishing development workflows and patterns

### Ongoing Development
Based on the codebase structure, active areas likely include:
- Caption pipeline optimization
- Real-time performance improvements
- Twitch Extension updates
- Translation feature enhancements
- Background job processing

## Next Steps

### Immediate
1. Complete memory bank documentation
2. Create domain-specific instruction files for:
   - GraphQL/Absinthe patterns
   - Testing strategies
   - Real-time features (Channels/LiveView)
   - Background jobs (Oban)
3. Document common workflows and tasks

### Short-term
- Review and update dependencies
- Performance profiling and optimization
- Test coverage improvements
- Error handling enhancements

### Medium-term
- Feature development priorities (check issue tracker)
- Scaling considerations for multi-server deployment
- Mobile app development
- Additional platform integrations (YouTube Live, etc.)

## Active Decisions & Considerations

### Speech Recognition Provider
**Decision**: Support both browser Web Speech API and Deepgram
- Browser API: Free, low latency, limited accuracy
- Deepgram: Higher cost, better accuracy, WebSocket overhead
- Using feature flags to switch between providers per user

### Translation Cost Management
**Decision**: Bits system to control translation costs
- Users purchase Bits for premium features
- Translations consume Bits based on usage
- Active debit tracking to prevent runaway costs
- Need to balance user value vs operational costs

### Real-time Architecture
**Decision**: Phoenix Channels + GraphQL Subscriptions
- Channels for streamer dashboard (bidirectional)
- GraphQL subscriptions for viewer extension (push-only)
- Allows independent scaling of different user types
- Redis PubSub for multi-node support

### Database Performance
**Consideration**: Growing transcripts table
- Need archival strategy for old captions
- Consider partitioning by date
- Add indexes for common query patterns
- Monitor query performance with Ecto telemetry

### Testing Strategy
**Focus Areas**:
- Caption pipeline unit tests (high priority)
- Channel integration tests
- GraphQL resolver tests
- LiveView feature tests
- Mock external APIs to avoid costs in tests

## Known Issues & Technical Debt

### High Priority
- Monitor Deepgram WebSocket connection stability
- Optimize translation caching to reduce Azure API calls
- Review Oban job retry strategies
- Database query optimizations (N+1 queries)

### Medium Priority
- Improve error messages for users
- Better handling of stream disconnections
- Caption history search performance
- Mobile responsive design improvements

### Low Priority
- Code documentation gaps
- Unused dependencies cleanup
- Consolidate similar service modules
- Refactor complex controller actions

## Environment & Deployment

### Current Setup
- **Production**: AWS Elastic Beanstalk
- **Database**: PostgreSQL on AWS RDS
- **Cache**: Redis (ElastiCache or standalone)
- **Monitoring**: New Relic APM
- **CI/CD**: GitHub Actions (likely)

### Development Environment
- Local PostgreSQL and Redis
- Mix tasks for database setup
- LiveReload for development
- IEx for debugging

## Feature Flags

Using `fun_with_flags` for feature control:
- `:caption_source` - Switch between speech providers
- Other flags TBD based on codebase exploration

## API Keys & Secrets

Required environment variables:
- Twitch credentials (client ID, secret, extension secret)
- Azure Cognitive Services (translation key, region)
- Deepgram API key
- New Relic license key
- Database URL
- Redis URL
- Secret key base

## Monitoring & Observability

### Metrics to Track
- Caption latency (speech → display)
- Transcription accuracy rates
- Translation API success/failure rates
- WebSocket connection stability
- Background job queue depth
- Database query performance
- Error rates by type

### Key Dashboards
- Real-time active streams
- Bits balance and consumption
- API rate limits and quotas
- System resource usage
- User engagement metrics

## Community & Support

### Key Channels
- GitHub repository: talk2MeGooseman/stream_closed_captioner_phoenix
- Twitch channel: https://twitch.tv/talk2megooseman
- Extension page: Twitch Extensions directory

### Documentation Needs
- User onboarding guide
- Troubleshooting common issues
- API documentation for developers
- Integration guides (OBS, Zoom)
- Accessibility best practices
