# Product Context

## Problem Statement

### Primary Problems
1. **Accessibility Barrier**: Millions of Twitch viewers who are deaf or hard of hearing cannot fully enjoy live streams
2. **Manual Effort**: Creating captions manually is time-consuming and impractical for live content
3. **Language Barriers**: Non-English speakers struggle to follow English-language streams
4. **Environment Limitations**: Viewers in quiet environments (work, public transit) can't engage with streams

### Current Pain Points
- No native Twitch closed captioning solution for live streams
- Third-party solutions are expensive or complex to set up
- Manual captioning services are prohibitively expensive for most streamers
- Lack of customization for caption appearance

## Solution

### How It Works
1. **Streamer Setup**: Install Twitch extension, authenticate, configure settings
2. **Start Captioning**: Click "Start Captions" in dashboard during stream
3. **Speech Recognition**: Browser captures audio and converts to text (or uses Deepgram)
4. **Processing Pipeline**: Text is filtered, translated (if enabled), and formatted
5. **Distribution**: Captions sent to Twitch extension overlay for all viewers
6. **Real-time Display**: Viewers see captions with zero manual intervention

### Key Workflows

#### Primary Workflow: Live Streaming
```
Streamer speaks → Browser/Deepgram captures audio →
Speech-to-text conversion → Captions pipeline (filtering, translation) →
Phoenix Channels broadcast → Twitch Extension displays →
Viewers see captions
```

#### Setup Workflow
```
Sign up with Twitch → Install Twitch Extension →
Configure caption settings → Test captions →
Go live with captions enabled
```

#### Translation Workflow
```
User purchases Bits → Enables translation to target language →
Captions automatically translated → Bits consumed per usage →
Balance tracked and displayed
```

## User Experience Goals

### For Streamers
- **Zero friction**: Start captions with one click
- **Reliable**: Works consistently without interruption
- **Customizable**: Control appearance, language, filtering
- **Affordable**: Free basic tier, optional premium features
- **Professional**: Captions look polished and professional

### For Viewers
- **Automatic**: No setup required, just watch the stream
- **Readable**: Clear, well-formatted, properly positioned
- **Accurate**: High-quality transcription with minimal errors
- **Customizable**: Adjust size, position (viewer-side controls)
- **Unobtrusive**: Doesn't interfere with stream content

## Feature Priority

### Must Have (Currently Implemented)
- Real-time speech-to-text captioning
- Twitch extension integration
- Basic caption customization
- Profanity filtering
- User authentication via Twitch
- Dashboard for configuration

### Should Have (In Progress/Planned)
- Multi-language translation
- OBS WebSocket integration
- Zoom integration
- VOD caption support
- Mobile app support
- Caption history/transcripts

### Nice to Have (Future)
- YouTube Live integration
- Custom vocabulary/training
- Multiple caption sources
- Team/moderator management
- Analytics dashboard
- Caption export formats

## Success Criteria
- Captions appear within 1-2 seconds of speech
- 90%+ transcription accuracy for clear audio
- Zero downtime during streams
- Positive feedback from accessibility community
- Growing monthly active streamers
- High Twitch extension retention rate
