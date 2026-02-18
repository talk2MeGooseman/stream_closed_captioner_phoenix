# Project Brief: Stream Closed Captioner Phoenix

## Overview
Stream Closed Captioner Phoenix is a real-time closed captioning service for Twitch streamers that provides accessible, customizable live captions during streams.

## Core Purpose
Enable Twitch streamers to provide real-time closed captions to their viewers, making streams more accessible to deaf/hard-of-hearing audiences and viewers who prefer text alongside audio.

## Key Features
- **Real-time Speech Recognition**: Browser-based and Deepgram integration for live transcription
- **Twitch Extension**: Browser overlay that displays captions directly on Twitch streams
- **Multi-language Support**: Translation capabilities using Azure Cognitive Services
- **OBS Integration**: Direct integration with OBS Studio via WebSocket
- **Zoom Integration**: Support for Zoom meeting captions
- **Customization**: Adjustable caption styles, positioning, and appearance
- **Content Filtering**: Profanity censoring and fun modes (pirate mode)
- **Bits System**: Virtual currency for premium features like translations
- **VOD Integration**: Add captions to Twitch VODs

## Target Users
- Twitch streamers who want to make their content accessible
- Viewers who are deaf or hard of hearing
- Viewers watching in sound-sensitive environments
- Non-native English speakers who benefit from text support

## Business Model
- Freemium model with basic captioning free
- Premium features (translations) available via Bits currency
- Twitch Extension installation required

## Technology Stack
- **Backend**: Elixir/Phoenix 1.7+
- **Database**: PostgreSQL with Ecto
- **Real-time**: Phoenix Channels, LiveView, WebSockets
- **API**: GraphQL via Absinthe
- **Frontend**: Stimulus.js, Tailwind CSS
- **Background Jobs**: Oban
- **Speech Recognition**: Browser Web Speech API, Deepgram
- **Translations**: Azure Cognitive Services
- **Caching**: Nebulex, Redis
- **Authentication**: Ueberauth (Twitch OAuth)
- **Monitoring**: New Relic

## Key Integrations
- Twitch Helix API
- Twitch Extension API
- OBS WebSocket
- Zoom API
- Deepgram Speech-to-Text
- Azure Cognitive Services

## Success Metrics
- Number of active streamers using the service
- Caption accuracy and latency
- Twitch extension installation rate
- User retention and engagement
- Bits consumption for premium features
