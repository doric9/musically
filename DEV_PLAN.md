# Piano Music Score App - Development Plan

## Project Overview

A real-time piano score following app that listens to piano playing and displays synchronized sheet music with auto-scrolling and intelligent zooming for comfortable viewing on small screens like smartphones.

### Core Features
1. **Real-time Audio Recognition** - Capture and analyze piano playing in real-time
2. **Auto-scrolling Score Display** - Eliminate manual page turning
3. **Intelligent Zoom** - Focus on currently playing section for small screen readability
4. **Mobile-First Design** - Optimized for smartphone displays

---

## Technical Architecture

### Tech Stack

#### Frontend
- **Framework**: React with TypeScript
- **Score Rendering**: [OpenSheetMusicDisplay](https://opensheetmusicdisplay.org/) or [VexFlow](https://vexflow.com/)
- **UI Library**: Tailwind CSS + shadcn/ui for responsive design
- **State Management**: Zustand or Redux Toolkit
- **Build Tool**: Vite

#### Audio Processing
- **Audio Capture**: Web Audio API (MediaStream)
- **Pitch Detection**: Web Audio API AnalyserNode + Custom pitch detection algorithm
- **Audio-to-MIDI**: Integration with Gemini API for intelligent transcription
- **Format Support**: MusicXML, MIDI input

#### Backend/API
- **Runtime**: Node.js with Express or Next.js API routes
- **AI Integration**: Google Gemini 2.5 Flash Native Audio (Live API)
- **Alternative Audio Analysis**: Basic Pitch or Spotify's audio analysis as fallback
- **Database**: PostgreSQL for user sessions, Firebase for real-time sync
- **File Storage**: Cloud Storage for uploaded scores (MusicXML/PDF)

#### Deployment
- **Frontend**: Vercel or Netlify
- **Backend**: Google Cloud Run or Vercel serverless functions
- **Mobile**: Progressive Web App (PWA) for cross-platform support

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      USER DEVICE                             │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              React Frontend (PWA)                       │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐  │ │
│  │  │ Audio Input  │  │ Score Viewer │  │ Zoom/Scroll │  │ │
│  │  │   Module     │  │   Component  │  │   Manager   │  │ │
│  │  └──────┬───────┘  └──────▲───────┘  └──────▲──────┘  │ │
│  │         │                  │                  │         │ │
│  │         │     ┌────────────┴──────────────────┘         │ │
│  │         │     │   Synchronization Engine                │ │
│  │         │     └────────────▲──────────────────┐         │ │
│  └─────────┼──────────────────┼──────────────────┼─────────┘ │
│            │                  │                  │           │
└────────────┼──────────────────┼──────────────────┼───────────┘
             │                  │                  │
             ▼                  │                  │
┌─────────────────────────┐     │                  │
│  Web Audio API          │     │                  │
│  ┌──────────────────┐   │     │                  │
│  │ MediaStream      │   │     │                  │
│  │ AnalyserNode     │   │     │                  │
│  │ AudioContext     │   │     │                  │
│  └──────────────────┘   │     │                  │
└───────────┬─────────────┘     │                  │
            │                   │                  │
            ▼                   │                  │
┌─────────────────────────┐     │                  │
│   Backend API Server    │     │                  │
│  ┌──────────────────┐   │     │                  │
│  │ Gemini Live API  │───┼─────┘                  │
│  │ (Audio Analysis) │   │                        │
│  ├──────────────────┤   │                        │
│  │ Score Manager    │───┼────────────────────────┘
│  │ (MusicXML/MIDI)  │   │
│  ├──────────────────┤   │
│  │ Position Tracker │   │
│  │ (Note → Score)   │   │
│  └──────────────────┘   │
└─────────────────────────┘
```

---

## Core Components

### 1. Audio Input Module
**Responsibility**: Capture and preprocess audio from microphone

**Implementation**:
```typescript
class AudioInputManager {
  - captureAudioStream(): MediaStream
  - initializeAudioContext(): AudioContext
  - createAnalyserNode(): AnalyserNode
  - getAudioData(): Float32Array
  - detectPitch(): number[]
  - sendToGemini(): Promise<NoteData>
}
```

**Key Features**:
- Request microphone permission
- Real-time audio buffering (low latency < 100ms)
- Frequency analysis using FFT
- Noise reduction/filtering
- Send audio chunks to Gemini Live API for transcription

---

### 2. Gemini Integration Service
**Responsibility**: Real-time audio-to-note transcription using Gemini 2.5 Flash Native Audio

**Implementation**:
```typescript
interface NoteData {
  pitch: string;        // e.g., "C4", "D#5"
  frequency: number;    // Hz
  timestamp: number;    // ms
  confidence: number;   // 0-1
  velocity: number;     // 0-127 (MIDI velocity)
}

class GeminiAudioService {
  - connectLiveAPI(): WebSocket
  - streamAudioChunks(audioData: Float32Array): void
  - parseNoteResponse(response: GeminiResponse): NoteData
  - getConfidenceScore(): number
  - handleErrors(): void
}
```

**API Integration**:
- Use Gemini Live API for real-time bidirectional streaming
- Send audio in 50-100ms chunks
- Receive structured note data with timestamps
- Fallback to Basic Pitch if Gemini fails

**Prompting Strategy**:
```
System: You are analyzing real-time piano audio.
For each audio segment, identify:
1. All notes being played (pitch notation)
2. Timing (onset and duration)
3. Confidence score
4. Velocity/dynamics

Return as JSON: { notes: [{ pitch, timestamp, duration, velocity }] }
```

---

### 3. Score Rendering Engine
**Responsibility**: Display sheet music and highlight current position

**Implementation**:
```typescript
class ScoreRenderer {
  - loadScore(musicXML: string): void
  - renderToCanvas(): void
  - highlightMeasure(measureIndex: number): void
  - highlightNote(noteId: string): void
  - getNoteBoundingBox(noteId: string): DOMRect
}
```

**Library Choice**: OpenSheetMusicDisplay
- Supports MusicXML (industry standard)
- HTML5 Canvas rendering
- Note-level addressability
- Customizable styling

**Features**:
- Load MusicXML files
- Render to scrollable canvas
- Highlight current note/measure
- Support for multi-staff piano scores
- Dynamic font sizing for zoom

---

### 4. Synchronization Engine
**Responsibility**: Match played notes to score position

**Implementation**:
```typescript
class SyncEngine {
  - scoreNotes: Note[]           // Pre-parsed from MusicXML
  - playedNotes: NoteData[]      // From Gemini API
  - currentPosition: ScorePosition

  - matchPlayedNoteToScore(played: NoteData): Note | null
  - calculatePositionConfidence(): number
  - handleMissedNotes(): void
  - handleExtraNotes(): void
  - predictNextPosition(): ScorePosition
  - updatePosition(newPosition: ScorePosition): void
}
```

**Algorithm**:
1. **Dynamic Time Warping (DTW)**: Match sequence of played notes to score
2. **Sliding Window**: Keep buffer of last N played notes
3. **Fuzzy Matching**: Allow for timing variations and missed notes
4. **Confidence Scoring**: Require 80%+ match before advancing position
5. **Predictive Scrolling**: Scroll slightly ahead based on tempo

**Challenges**:
- Handle timing variations (human performance != perfect timing)
- Deal with wrong notes gracefully
- Detect repeats and jumps (D.C., D.S., Coda)
- Multi-voice piano scores (left hand vs right hand)

---

### 5. Auto-Scroll Manager
**Responsibility**: Smooth scrolling to keep current measure visible

**Implementation**:
```typescript
class AutoScrollManager {
  - viewportHeight: number
  - scrollPosition: number
  - targetMeasure: number

  - calculateScrollTarget(measureBounds: DOMRect): number
  - smoothScrollTo(targetY: number, duration: number): void
  - predictScrollPosition(tempo: number): number
  - adjustScrollSpeed(playbackSpeed: number): void
}
```

**Features**:
- Smooth CSS transitions (300-500ms)
- Look-ahead: Show 2-3 measures ahead
- Adaptive scrolling based on tempo
- Snap to measure boundaries
- Pause scrolling when user manually scrolls (resume after 3 seconds)

---

### 6. Intelligent Zoom Controller
**Responsibility**: Dynamically zoom to fit current section on small screens

**Implementation**:
```typescript
class ZoomController {
  - baseZoomLevel: number = 1.0
  - currentZoomLevel: number
  - focusArea: BoundingBox

  - calculateOptimalZoom(measure: Measure, screenSize: Dimensions): number
  - zoomToMeasure(measureIndex: number): void
  - zoomToNoteGroup(notes: Note[]): void
  - animateZoomTransition(from: number, to: number): void
}
```

**Zoom Strategy**:
- **Mobile (< 768px)**: Zoom to show 1-2 measures
- **Tablet (768-1024px)**: Show 2-4 measures
- **Desktop (> 1024px)**: Show full system or more

**Adaptive Zoom**:
- Dense sections (many notes): Zoom in more
- Sparse sections: Zoom out to show context
- Respect user manual zoom (override for 5 seconds)

---

## Data Models

### MusicXML Score Data
```typescript
interface Score {
  id: string;
  title: string;
  composer: string;
  musicXML: string;
  measures: Measure[];
  tempo: number;
  timeSignature: { beats: number; beatType: number };
}

interface Measure {
  index: number;
  notes: Note[];
  startTime: number;  // Expected time in ms from start
  duration: number;   // Total duration in ms
  bounds: BoundingBox; // Visual position in rendered score
}

interface Note {
  id: string;
  pitch: string;      // "C4", "D#5", etc.
  octave: number;
  duration: number;   // In beats
  staff: number;      // 0=treble, 1=bass for piano
  voice: number;      // For polyphony
  measureIndex: number;
  positionInMeasure: number; // Beat position
  bounds: BoundingBox;
}
```

### Real-time Playback State
```typescript
interface PlaybackState {
  currentMeasure: number;
  currentBeat: number;
  playedNotes: NoteData[];
  matchConfidence: number;
  isFollowing: boolean;
  tempo: number;        // Actual detected tempo
  scrollPosition: number;
  zoomLevel: number;
}
```

---

## Implementation Phases

### Phase 1: Project Setup & Basic UI (Week 1)
**Goals**:
- Initialize React + TypeScript project
- Set up basic score viewer
- Implement responsive layout

**Tasks**:
1. Create React app with Vite
2. Install dependencies (OpenSheetMusicDisplay, Tailwind, etc.)
3. Set up project structure and routing
4. Create basic UI components:
   - Header with controls (play/pause, settings)
   - Score viewer container
   - Zoom controls
5. Implement basic MusicXML loading and rendering
6. Test with sample piano scores

**Deliverables**:
- Working app that can load and display piano scores
- Responsive layout for mobile/tablet/desktop
- Manual zoom and scroll controls

---

### Phase 2: Audio Capture & Gemini Integration (Week 2-3)
**Goals**:
- Capture microphone audio
- Integrate Gemini Live API
- Real-time note detection

**Tasks**:
1. Implement audio input using Web Audio API
2. Set up Google Cloud project and enable Gemini API
3. Create backend API for Gemini Live API proxy
4. Implement audio streaming to Gemini
5. Parse Gemini responses into structured note data
6. Display detected notes in real-time (console/debug view)
7. Implement pitch detection fallback using Web Audio API
8. Test with recorded piano audio samples

**Deliverables**:
- Real-time audio capture and visualization
- Gemini API integration working
- Note detection accuracy > 90% for clean audio
- Debug panel showing detected notes

---

### Phase 3: Score Synchronization (Week 4-5)
**Goals**:
- Match played notes to score
- Track current position accurately

**Tasks**:
1. Parse MusicXML to extract note sequences
2. Implement note matching algorithm (DTW-based)
3. Create score position tracking system
4. Handle timing variations and errors gracefully
5. Implement confidence scoring
6. Add visual feedback (highlight current note/measure)
7. Test with various playing speeds and styles
8. Fine-tune matching thresholds

**Deliverables**:
- Reliable note-to-score matching
- Visual indication of current position
- Graceful handling of mistakes
- Position confidence indicator

---

### Phase 4: Auto-Scroll Implementation (Week 6)
**Goals**:
- Smooth auto-scrolling synchronized with playback
- Predictive scrolling for seamless experience

**Tasks**:
1. Calculate scroll targets based on measure positions
2. Implement smooth scrolling animations
3. Add look-ahead scrolling (show upcoming measures)
4. Implement tempo-adaptive scrolling
5. Add manual scroll override with auto-resume
6. Test scrolling at various tempos
7. Optimize scrolling performance on mobile

**Deliverables**:
- Smooth auto-scrolling that keeps current position visible
- No jarring jumps or lags
- Works reliably on mobile devices

---

### Phase 5: Intelligent Zoom (Week 7)
**Goals**:
- Dynamic zoom based on screen size
- Focus on relevant section

**Tasks**:
1. Implement measure-level zoom calculations
2. Create adaptive zoom logic (based on note density)
3. Add smooth zoom transitions
4. Test on various screen sizes (phone, tablet, desktop)
5. Implement user manual zoom with temporary override
6. Add pinch-to-zoom gesture support for mobile
7. Optimize rendering performance at high zoom levels

**Deliverables**:
- Automatic zoom that makes scores readable on phones
- Smooth zoom transitions
- User can override when needed
- Good performance even with complex scores

---

### Phase 6: Polish & Optimization (Week 8-9)
**Goals**:
- Performance optimization
- Error handling
- User experience refinement

**Tasks**:
1. Optimize audio processing (reduce latency)
2. Improve Gemini API error handling and fallbacks
3. Add loading states and error messages
4. Implement score library (upload/select scores)
5. Add user settings (zoom preferences, scroll behavior)
6. Implement offline support (PWA with service workers)
7. Add onboarding tutorial
8. Performance testing and optimization
9. Cross-browser testing
10. Accessibility improvements (keyboard navigation, ARIA)

**Deliverables**:
- Production-ready app
- < 200ms latency for note detection
- Comprehensive error handling
- Smooth 60fps rendering
- Works offline (after first load)

---

### Phase 7: Advanced Features (Week 10+)
**Optional enhancements**:

1. **Practice Mode**
   - Slow down playback
   - Loop difficult sections
   - Metronome integration

2. **Performance Analysis**
   - Track accuracy over time
   - Identify problematic measures
   - Progress visualization

3. **Multi-format Support**
   - PDF score import (via OCR/OMR)
   - Import from MIDI files
   - Export practice sessions

4. **Social Features**
   - Share performances
   - Community score library
   - Comments and annotations

5. **AI Assistant**
   - Use Gemini for practice tips
   - Suggest fingerings
   - Detect and correct rhythm issues

---

## Technical Challenges & Solutions

### Challenge 1: Gemini API Limitations for Music
**Problem**: Gemini may not have specific piano note detection capabilities out-of-the-box

**Solutions**:
1. **Prompt Engineering**: Carefully craft prompts to guide Gemini
   - "Analyze this piano audio and identify each note played..."
   - Provide example outputs in the system prompt
2. **Hybrid Approach**:
   - Use Web Audio API for basic pitch detection
   - Use Gemini for validation and musical context understanding
3. **Training/Fine-tuning**: If available, fine-tune on piano audio dataset
4. **Fallback**: Use Basic Pitch (Spotify's open-source model) when Gemini fails

### Challenge 2: Real-time Performance
**Problem**: Audio processing + AI inference + rendering = potential lag

**Solutions**:
1. **Optimized Pipeline**:
   - Web Workers for audio processing (off main thread)
   - Debounce Gemini API calls (batch audio chunks)
   - Request Animation Frame for smooth rendering
2. **Predictive Algorithms**:
   - Predict next notes based on score
   - Pre-render upcoming measures
   - Cache rendered score segments
3. **Adaptive Quality**:
   - Reduce audio sample rate on slower devices
   - Simplify rendering on mobile
   - Progressive enhancement

### Challenge 3: Timing Variations
**Problem**: Human playing is not perfectly aligned with score timing

**Solutions**:
1. **Flexible Matching**:
   - Allow ±20% timing tolerance
   - Use DTW for sequence matching (not exact timing)
2. **Tempo Detection**:
   - Continuously update tempo based on actual playing
   - Adapt expected timings dynamically
3. **Error Recovery**:
   - If lost, use unique measure patterns to re-sync
   - Allow user to manually reset position

### Challenge 4: Complex Piano Scores
**Problem**: Piano music has 2 staves, multiple voices, chords

**Solutions**:
1. **Multi-voice Tracking**:
   - Track left and right hand separately
   - Match chords as groups, not individual notes
2. **Staff-aware Rendering**:
   - Render treble and bass clefs properly
   - Support grand staff highlighting
3. **Simplification Mode**:
   - Option to show single staff for beginners
   - Hide less important notes (grace notes, ornaments)

### Challenge 5: Mobile Performance
**Problem**: Limited CPU, GPU, battery on phones

**Solutions**:
1. **Efficient Rendering**:
   - Use Canvas instead of SVG for better performance
   - Lazy render only visible measures
   - Reduce re-renders with React.memo and useMemo
2. **Battery Optimization**:
   - Reduce Gemini API call frequency when on battery
   - Use requestIdleCallback for non-critical tasks
   - Implement sleep mode when idle
3. **Network Efficiency**:
   - Cache scores locally (IndexedDB)
   - Compress audio before sending to API
   - Use WebSocket for Gemini (avoid HTTP overhead)

---

## API Design

### REST Endpoints

```
POST /api/scores/upload
- Upload MusicXML file
- Response: { scoreId, title, preview }

GET /api/scores/:id
- Retrieve score data
- Response: { score: Score }

POST /api/audio/analyze
- Send audio chunk for analysis (fallback to REST)
- Response: { notes: NoteData[] }

GET /api/user/sessions
- Get practice session history
- Response: { sessions: Session[] }
```

### WebSocket Events (Gemini Live API)

```
Client -> Server:
- connect: { apiKey, sessionId }
- audio_chunk: { data: ArrayBuffer, timestamp }
- pause: {}
- resume: {}

Server -> Client:
- connected: { sessionId }
- note_detected: { notes: NoteData[] }
- error: { message, code }
- latency: { ms }
```

---

## Environment Variables

```env
# Google Cloud / Gemini
GOOGLE_CLOUD_PROJECT_ID=your-project-id
GEMINI_API_KEY=your-api-key
GEMINI_MODEL=gemini-2.5-flash-native-audio

# Backend
PORT=3000
NODE_ENV=development

# Database (optional)
DATABASE_URL=postgresql://...

# Storage (optional)
STORAGE_BUCKET=musically-scores
```

---

## Testing Strategy

### Unit Tests
- Audio processing functions
- Note matching algorithm
- Score parsing
- Zoom/scroll calculations

### Integration Tests
- Audio capture -> Gemini -> Note detection pipeline
- Score loading -> Rendering
- Sync engine with mock playback

### E2E Tests (Playwright/Cypress)
- Complete user flow: Load score -> Play -> Auto-scroll
- Mobile responsive behavior
- Error handling (API failures, permission denied)

### Performance Tests
- Audio latency benchmarks (target: < 200ms)
- Rendering FPS (target: 60fps)
- Memory usage (target: < 100MB on mobile)

### User Testing
- Test with real pianists of various skill levels
- Gather feedback on timing accuracy
- Measure usability on different devices

---

## Success Metrics

1. **Accuracy**: > 90% note detection accuracy for clean audio
2. **Latency**: < 200ms from note played to highlight on screen
3. **Performance**: 60fps rendering, < 100ms scroll lag
4. **Usability**: Users can comfortably play on smartphone screen
5. **Reliability**: < 1% error rate in sync engine over 5-minute session

---

## Project Timeline

| Phase | Duration | Milestone |
|-------|----------|-----------|
| Phase 1: Setup & UI | 1 week | Can display scores |
| Phase 2: Audio & Gemini | 2 weeks | Real-time note detection |
| Phase 3: Synchronization | 2 weeks | Notes match score |
| Phase 4: Auto-scroll | 1 week | Scrolls automatically |
| Phase 5: Smart zoom | 1 week | Readable on mobile |
| Phase 6: Polish | 2 weeks | Production ready |
| **Total MVP** | **9 weeks** | **Fully functional app** |
| Phase 7: Advanced | Ongoing | Enhanced features |

---

## Risk Mitigation

### Risk 1: Gemini API Cost
**Impact**: High usage costs for real-time audio streaming
**Mitigation**:
- Implement usage quotas per user
- Offer freemium model (limited sessions)
- Use efficient audio compression
- Cache and reuse analysis when possible

### Risk 2: Accuracy Issues
**Impact**: Poor note detection frustrates users
**Mitigation**:
- Provide manual position override
- Show confidence scores
- Allow users to report issues
- Implement fallback algorithms

### Risk 3: Network Dependency
**Impact**: App unusable without internet
**Mitigation**:
- Implement offline mode with local pitch detection
- Cache Gemini responses for common patterns
- Progressive Web App for offline capability
- Clear UX for network status

### Risk 4: Limited Score Library
**Impact**: Users have nothing to play
**Mitigation**:
- Partner with sheet music providers
- Support user uploads (MusicXML)
- Include public domain scores
- Build conversion tools (PDF -> MusicXML)

---

## Resources & References

### Gemini API Documentation
- [Audio understanding | Gemini API](https://ai.google.dev/gemini-api/docs/audio)
- [Gemini Live API overview](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/live-api)
- [Get started with Live API](https://ai.google.dev/gemini-api/docs/live)

### Audio-to-MIDI Tools
- [Building a GenAI-Powered Audio-to-MIDI Transcription Pipeline](https://medium.com/@bmonobina/building-a-genai-powered-audio-to-midi-transcription-pipeline-with-google-cloud-and-vertex-ai-90d910d2ec4c)
- [Google Gemini Music Generation | MIDI Agent](https://www.midiagent.com/google-gemini-music-generation)

### Music Rendering Libraries
- OpenSheetMusicDisplay: https://opensheetmusicdisplay.org/
- VexFlow: https://vexflow.com/
- ABCjs: https://www.abcjs.net/

### Audio Processing
- Web Audio API: https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API
- Basic Pitch (Spotify): https://github.com/spotify/basic-pitch

### Similar Projects (for inspiration)
- Soundslice: https://www.soundslice.com/
- Flat.io: https://flat.io/
- MuseScore: https://musescore.org/

---

## Next Steps

1. **Review and approve this plan**
2. **Set up development environment**
3. **Create GitHub repository structure**
4. **Start Phase 1: Project setup**
5. **Establish CI/CD pipeline**
6. **Begin implementation**

---

*This development plan is a living document and will be updated as the project evolves.*
