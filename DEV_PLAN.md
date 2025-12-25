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

#### Mobile App (Android)
- **Framework**: React Native with TypeScript
- **Platform**: Android (primary), iOS compatible (future)
- **Navigation**: React Navigation
- **Score Rendering**:
  - react-native-svg + Custom renderer for MusicXML
  - OR WebView with VexFlow/OSMD for score display
- **UI Library**: React Native Paper or NativeBase
- **State Management**: Zustand or Redux Toolkit
- **Build Tool**: Metro bundler (React Native default)

#### Audio Processing
- **Audio Capture**:
  - react-native-audio-recorder-player for recording
  - react-native-audio for real-time audio capture
  - Android AudioRecord API (native module if needed)
- **Audio Format**: PCM audio streaming to Gemini
- **Audio-to-MIDI**: Integration with Gemini 3 Flash API for intelligent transcription
- **Permissions**: RECORD_AUDIO, READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE
- **Format Support**: MusicXML, MIDI input

#### Backend/API
- **Runtime**: Node.js with Express or Firebase Cloud Functions
- **AI Integration**: Google Gemini 3 Flash (Live API) - 3x cheaper for audio input
- **Alternative Audio Analysis**: Basic Pitch or Spotify's audio analysis as fallback
- **Database**: Firebase Firestore for user sessions and real-time sync
- **File Storage**: Firebase Storage for uploaded scores (MusicXML/PDF)
- **Authentication**: Firebase Auth (optional)

#### Deployment
- **Android**: Google Play Store (APK/AAB)
- **Backend**: Firebase Cloud Functions or Google Cloud Run
- **Distribution**: Initially beta testing via Firebase App Distribution
- **Future**: iOS App Store (React Native allows easy porting)

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   ANDROID DEVICE                             │
│  ┌────────────────────────────────────────────────────────┐ │
│  │         React Native App (TypeScript)                   │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐  │ │
│  │  │ Audio Input  │  │ Score Viewer │  │ Zoom/Scroll │  │ │
│  │  │   Module     │  │  (SVG/WebV)  │  │   Manager   │  │ │
│  │  └──────┬───────┘  └──────▲───────┘  └──────▲──────┘  │ │
│  │         │                  │                  │         │ │
│  │         │     ┌────────────┴──────────────────┘         │ │
│  │         │     │   Synchronization Engine                │ │
│  │         │     └────────────▲──────────────────┐         │ │
│  └─────────┼──────────────────┼──────────────────┼─────────┘ │
│            │                  │                  │           │
│  ┌─────────▼──────────────┐   │                  │           │
│  │ Android Audio APIs     │   │                  │           │
│  │ ┌────────────────────┐ │   │                  │           │
│  │ │ AudioRecord        │ │   │                  │           │
│  │ │ react-native-audio │ │   │                  │           │
│  │ └────────────────────┘ │   │                  │           │
│  └─────────┬──────────────┘   │                  │           │
│            │                  │                  │           │
└────────────┼──────────────────┼──────────────────┼───────────┘
             │                  │                  │
             │ (HTTPS/WebSocket)│                  │
             ▼                  │                  │
┌──────────────────────────────────────────────────┐
│          Backend (Firebase/Cloud Run)            │
│  ┌────────────────────────────────────────────┐  │
│  │  Gemini 3 Flash Live API Integration      │  │
│  │  ┌──────────────────────────────────────┐ │  │
│  │  │ Audio Stream Handler                 │ │  │
│  │  │ (Receives PCM audio chunks)          │ │  │
│  │  └───────────┬──────────────────────────┘ │  │
│  │              │                             │  │
│  │              ▼                             │  │
│  │  ┌──────────────────────────────────────┐ │  │
│  │  │ Gemini 3 Flash API                   │ │  │
│  │  │ - Real-time audio transcription      │ │  │
│  │  │ - Returns: notes, timing, confidence │ │  │
│  │  └───────────┬──────────────────────────┘ │  │
│  └──────────────┼────────────────────────────┘  │
│                 │                                │
│  ┌──────────────▼────────────────────────────┐  │
│  │ Firebase Services                         │  │
│  │ - Firestore: User sessions, scores        │  │
│  │ - Storage: MusicXML/PDF files             │  │
│  │ - Auth: User authentication (optional)    │  │
│  └───────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘
```

---

## Core Components

### 1. Audio Input Module (React Native)
**Responsibility**: Capture and preprocess audio from microphone on Android

**Implementation**:
```typescript
import AudioRecord from 'react-native-audio-record';

class AudioInputManager {
  private audioRecord: AudioRecord;
  private audioBuffer: number[] = [];

  - async requestPermissions(): Promise<boolean>
  - initializeAudioRecord(config: AudioConfig): void
  - startRecording(): void
  - stopRecording(): void
  - onAudioData(data: AudioData): void
  - processAudioChunk(chunk: Float32Array): void
  - sendToGemini(audioData: Float32Array): Promise<NoteData>
}

// Audio configuration for Android
interface AudioConfig {
  sampleRate: 44100;          // Hz
  channels: 1;                // Mono
  bitsPerSample: 16;          // 16-bit PCM
  audioSource: 'MIC';         // Microphone input
  bufferSize: 4096;           // samples
}
```

**Key Features**:
- Request Android RECORD_AUDIO permission at runtime
- Real-time PCM audio capture using AudioRecord
- Audio buffering with low latency (< 100ms target)
- Convert PCM to format suitable for Gemini API
- Stream audio chunks via WebSocket to backend
- Handle audio focus and lifecycle (pause on phone calls)

**Android-Specific Considerations**:
- Handle different Android versions (API level compatibility)
- Audio session management (MediaPlayer compatibility)
- Battery optimization (reduce sample rate when battery low)
- Background audio permission (Android 9+)

---

### 2. Gemini Integration Service
**Responsibility**: Real-time audio-to-note transcription using Gemini 3 Flash

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

### 3. Score Rendering Engine (React Native)
**Responsibility**: Display sheet music and highlight current position on Android

**Implementation Options**:

**Option A: WebView with OSMD/VexFlow (Recommended)**
```typescript
import { WebView } from 'react-native-webview';

class ScoreRenderer {
  private webViewRef: React.RefObject<WebView>;

  - loadScore(musicXML: string): void
  - injectJavaScript(code: string): void
  - highlightMeasure(measureIndex: number): void
  - highlightNote(noteId: string): void
  - onMessage(event: WebViewMessageEvent): void
  - getNoteBoundingBox(noteId: string): Promise<Rect>
}
```

**Option B: react-native-svg (Custom Renderer)**
```typescript
import Svg, { Path, Circle, Text } from 'react-native-svg';

class SVGScoreRenderer {
  - parseMusicXML(xml: string): ScoreElements
  - renderStaff(staff: Staff): JSX.Element
  - renderNotes(notes: Note[]): JSX.Element[]
  - highlightNote(noteId: string): void
}
```

**Recommended Approach**: WebView + OpenSheetMusicDisplay
- Leverage mature web libraries (OSMD, VexFlow)
- MusicXML support out of the box
- Better performance for complex scores
- Easier highlighting and interaction via JavaScript injection
- Message passing between React Native ↔ WebView for events

**Features**:
- Load MusicXML files from local storage or Firebase
- Render to scrollable view (ScrollView wrapper)
- Highlight current note/measure with color overlay
- Support for multi-staff piano scores (grand staff)
- Dynamic zoom via WebView scale or SVG viewBox
- Gesture handling (pinch-to-zoom, pan)

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

### 5. Auto-Scroll Manager (React Native)
**Responsibility**: Smooth scrolling to keep current measure visible on Android

**Implementation**:
```typescript
import { ScrollView, Animated } from 'react-native';

class AutoScrollManager {
  private scrollViewRef: React.RefObject<ScrollView>;
  private scrollAnim: Animated.Value;
  private viewportHeight: number;
  private scrollPosition: number;
  private targetMeasure: number;
  private isUserScrolling: boolean = false;

  - calculateScrollTarget(measureBounds: Rect): number
  - smoothScrollTo(targetY: number, duration: number): void
  - animateScroll(targetY: number): void
  - predictScrollPosition(tempo: number): number
  - adjustScrollSpeed(playbackSpeed: number): void
  - onScrollBeginDrag(): void  // User started scrolling
  - onScrollEndDrag(): void    // User stopped scrolling
}
```

**Features**:
- Smooth animations using Animated API (300-500ms easing)
- Look-ahead: Show 2-3 measures ahead of current position
- Adaptive scrolling based on detected tempo
- Snap to measure boundaries
- Pause auto-scroll when user manually scrolls (resume after 3 seconds)
- Handle orientation changes (portrait/landscape)

**React Native Specific**:
- Use `ScrollView.scrollTo()` with `animated: true`
- Monitor scroll events with `onScroll` handler
- Detect user interaction vs programmatic scroll
- Optimize scroll performance with `removeClippedSubviews`

---

### 6. Intelligent Zoom Controller (React Native)
**Responsibility**: Dynamically zoom to fit current section on Android screens

**Implementation**:
```typescript
import { Dimensions, PanResponder, Animated } from 'react-native';

class ZoomController {
  private baseZoomLevel: number = 1.0;
  private currentZoomLevel: number;
  private zoomAnim: Animated.Value;
  private panResponder: PanResponder;
  private focusArea: BoundingBox;
  private screenDimensions: { width: number; height: number };

  - calculateOptimalZoom(measure: Measure, screenSize: Dimensions): number
  - zoomToMeasure(measureIndex: number): void
  - zoomToNoteGroup(notes: Note[]): void
  - animateZoomTransition(from: number, to: number): void
  - handlePinchGesture(event: GestureEvent): void
  - onLayout(event: LayoutChangeEvent): void
}
```

**Zoom Strategy** (Android screen sizes):
- **Phone Portrait (< 600dp)**: Zoom to show 1-2 measures
- **Phone Landscape**: Show 2-3 measures
- **Tablet (> 600dp)**: Show 3-5 measures
- **Large Tablet (> 800dp)**: Show full system

**Adaptive Zoom**:
- Dense sections (many notes): Zoom in more for readability
- Sparse sections: Zoom out to show musical context
- Respect user manual zoom with pinch gesture (override auto-zoom for 5 seconds)
- Save user zoom preference per score in AsyncStorage

**React Native Specific**:
- Use `react-native-gesture-handler` for smooth pinch-to-zoom
- Animated.Value for zoom transformations
- Handle orientation changes (Dimensions.addEventListener)
- WebView: Inject JavaScript to set zoom level
- SVG: Adjust viewBox dimensions

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

### Phase 1: React Native Project Setup & Basic UI (Week 1)
**Goals**:
- Initialize React Native Android project
- Set up basic score viewer
- Implement Android UI layout

**Tasks**:
1. Initialize React Native project with TypeScript template
   ```bash
   npx react-native init Musically --template react-native-template-typescript
   ```
2. Configure Android development environment (Android Studio, SDK)
3. Install core dependencies:
   - `react-navigation` (navigation)
   - `react-native-webview` (for score rendering)
   - `react-native-gesture-handler` (gestures)
   - `react-native-paper` or `nativebase` (UI components)
   - `@react-native-async-storage/async-storage` (local storage)
4. Set up project structure:
   ```
   src/
   ├── components/      (ScoreViewer, AudioControls, etc.)
   ├── screens/         (HomeScreen, PracticeScreen, etc.)
   ├── services/        (AudioService, GeminiService, etc.)
   ├── stores/          (state management)
   ├── utils/           (helpers)
   └── types/           (TypeScript types)
   ```
5. Create basic UI screens:
   - Home screen with score selection
   - Practice screen with score viewer
   - Settings screen
6. Implement WebView-based score viewer with OSMD
7. Add sample MusicXML files to test rendering
8. Configure Android permissions in `AndroidManifest.xml`

**Deliverables**:
- Working React Native Android app
- Can load and display piano scores in WebView
- Basic navigation between screens
- Runs on Android emulator and physical device
- Manual zoom and scroll controls working

---

### Phase 2: Audio Capture & Gemini Integration (Week 2-3)
**Goals**:
- Capture microphone audio on Android
- Integrate Gemini 3 Flash Live API
- Real-time note detection

**Tasks**:
1. **Android Audio Setup**:
   - Install `react-native-audio-record` or `react-native-audio`
   - Request RECORD_AUDIO permission at runtime
   - Configure audio recording parameters (44.1kHz, mono, 16-bit PCM)
   - Test audio capture on physical device (emulator has limited audio)

2. **Backend API Setup**:
   - Set up Firebase project or Node.js backend on Cloud Run
   - Enable Gemini API in Google Cloud Console
   - Create WebSocket endpoint for real-time audio streaming
   - Implement Gemini 3 Flash Live API integration
   - Set up environment variables and API keys

3. **Audio Streaming Pipeline**:
   - Capture audio chunks (100ms buffers)
   - Convert to appropriate format for Gemini API
   - Stream audio via WebSocket to backend
   - Backend forwards to Gemini Live API
   - Receive note detection responses in real-time

4. **Integration & Testing**:
   - Parse Gemini responses into NoteData format
   - Display detected notes in debug overlay
   - Add audio visualization (waveform/spectrum)
   - Test with pre-recorded piano samples
   - Test with live piano/keyboard input
   - Measure and optimize latency (target < 200ms)

**Deliverables**:
- Real-time audio capture working on Android
- Gemini 3 Flash API integration functional
- Note detection accuracy > 90% for clean audio
- Debug panel showing detected notes with confidence scores
- End-to-end latency < 300ms (Android → Backend → Gemini → Response)

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

### Challenge 2: Real-time Performance (Android)
**Problem**: Audio processing + AI inference + rendering = potential lag on mobile devices

**Solutions**:
1. **Optimized Pipeline**:
   - Use native audio processing (avoid JS bridge overhead)
   - Process audio in separate thread (React Native native module)
   - Batch audio chunks efficiently (minimize network calls)
   - Use Animated API for 60fps rendering
   - Optimize WebView performance (disable unnecessary features)
2. **Predictive Algorithms**:
   - Predict next notes based on score and tempo
   - Pre-load upcoming measures in WebView
   - Cache rendered score segments in memory
   - Preemptive scrolling based on note velocity
3. **Adaptive Quality**:
   - Reduce audio sample rate on low-end devices (22kHz vs 44kHz)
   - Simplify score rendering (hide ornaments, dynamics)
   - Lower WebView resolution on older devices
   - Monitor battery level and adjust accordingly
4. **Android Optimization**:
   - Use `InteractionManager` to defer non-critical tasks
   - Enable Hermes JavaScript engine for better performance
   - Optimize bundle size with tree shaking
   - Use `react-native-fast-image` for efficient image loading

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

### Challenge 5: Android Device Performance & Battery
**Problem**: Limited CPU, GPU, battery on Android phones; wide range of device capabilities

**Solutions**:
1. **Efficient Rendering**:
   - Use WebView with hardware acceleration enabled
   - Lazy load measures (render only visible viewport)
   - Optimize React Native re-renders with React.memo and useMemo
   - Use `removeClippedSubviews` on ScrollView
   - Enable Hermes for faster JS execution
2. **Battery Optimization**:
   - Monitor battery level with `react-native-device-info`
   - Reduce Gemini API call frequency when battery < 20%
   - Lower audio sample rate on low battery (44.1kHz → 22kHz)
   - Pause background processing when app is inactive
   - Use Android's Doze mode compatibility
3. **Network Efficiency**:
   - Cache scores locally with AsyncStorage or SQLite
   - Compress audio before sending (use Opus codec if supported)
   - Use WebSocket for persistent connection (lower overhead than HTTP)
   - Implement retry logic with exponential backoff
   - Download scores on WiFi, use cached versions on cellular
4. **Device Compatibility**:
   - Support Android API 21+ (Android 5.0+)
   - Test on low-end devices (2GB RAM, older processors)
   - Graceful degradation (disable features on old devices)
   - Device-specific audio latency compensation
5. **Memory Management**:
   - Clear audio buffers after processing
   - Unload unused score data
   - Use pagination for large score libraries
   - Monitor memory usage and warn user if critical

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

### Backend (.env)
```env
# Google Cloud / Gemini
GOOGLE_CLOUD_PROJECT_ID=your-project-id
GEMINI_API_KEY=your-api-key
GEMINI_MODEL=gemini-3-flash

# Firebase (if using Firebase)
FIREBASE_PROJECT_ID=your-firebase-project
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email

# Backend
PORT=3000
NODE_ENV=development
WEBSOCKET_PORT=8080

# Storage
STORAGE_BUCKET=musically-scores
```

### React Native App (config.ts)
```typescript
export const Config = {
  API_BASE_URL: __DEV__
    ? 'http://10.0.2.2:3000'  // Android emulator
    : 'https://your-backend.com',

  WEBSOCKET_URL: __DEV__
    ? 'ws://10.0.2.2:8080'
    : 'wss://your-backend.com',

  FIREBASE_CONFIG: {
    apiKey: 'your-api-key',
    authDomain: 'your-app.firebaseapp.com',
    projectId: 'your-project-id',
    storageBucket: 'your-app.appspot.com',
    messagingSenderId: 'your-sender-id',
    appId: 'your-app-id',
  },

  AUDIO_CONFIG: {
    sampleRate: 44100,
    channels: 1,
    bitsPerSample: 16,
    chunkDuration: 100, // ms
  },
};
```

### Android Configuration (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

---

## Testing Strategy

### Unit Tests (Jest + React Native Testing Library)
```bash
npm test
```
- Audio processing functions
- Note matching algorithm (DTW implementation)
- MusicXML parsing logic
- Zoom/scroll calculation algorithms
- State management (stores/reducers)
- Utility functions

### Integration Tests
```bash
npm run test:integration
```
- Android audio capture → WebSocket → Backend → Gemini pipeline
- Score loading from Firebase → WebView rendering
- Sync engine with mock audio input
- Permission handling flows (runtime permissions)
- Network retry logic and error recovery

### E2E Tests (Detox)
```bash
detox test --configuration android.emu.debug
```
- Complete user flow: Launch → Select score → Grant permissions → Play → Auto-scroll
- Permission handling (microphone, storage)
- Error states (no network, API failure, invalid score)
- Background/foreground transitions
- Orientation changes (portrait/landscape)
- Different Android devices and API levels

### Performance Tests
- **Audio Latency**: Measure end-to-end latency (target: < 300ms on Android)
  - Note played → Audio captured → Sent to Gemini → Response → UI update
- **Rendering FPS**: Monitor frame rate during scroll/zoom (target: 60fps)
  - Use React DevTools Profiler
  - Android Systrace for native performance
- **Memory Usage**: Profile with Android Studio Memory Profiler
  - Target: < 150MB RAM on mid-range devices
  - No memory leaks during extended sessions
- **Battery Drain**: Measure power consumption
  - Target: < 10% battery per hour of practice
  - Test on physical devices, not emulator

### Device Testing Matrix
**Minimum supported**: Android API 21 (Android 5.0)
- **Low-end**: Android 8.0, 2GB RAM, Snapdragon 400-series
- **Mid-range**: Android 11, 4GB RAM, Snapdragon 600-series
- **High-end**: Android 13+, 8GB+ RAM, Snapdragon 800-series
- **Tablet**: 10" screen, Android 11+

### User Testing
- Test with real pianists (beginner, intermediate, advanced)
- Gather feedback on:
  - Note detection accuracy
  - Auto-scroll timing
  - Zoom level comfort
  - Overall usability
- Test on multiple devices (different screen sizes, Android versions)
- A/B test different scroll speeds and zoom strategies

---

## Success Metrics

1. **Accuracy**: > 90% note detection accuracy for clean audio (measured with test dataset)
2. **Latency**: < 300ms from note played to highlight on screen (Android end-to-end)
3. **Performance**:
   - 60fps rendering during scroll and zoom animations
   - < 100ms scroll lag
   - < 150MB RAM usage on mid-range devices
   - < 10% battery drain per hour
4. **Usability**:
   - Users can comfortably read and play on 5.5"+ smartphone screens
   - Score is readable without manual zoom adjustment
   - App is usable in both portrait and landscape orientations
5. **Reliability**:
   - < 1% error rate in sync engine over 5-minute practice session
   - < 0.1% crash rate
   - Works offline (scores cached locally)
   - Graceful degradation when network is unavailable
6. **User Satisfaction** (post-beta survey):
   - 4+ stars average rating
   - 80%+ would recommend to other pianists
   - 70%+ prefer this over traditional sheet music

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
- Using Gemini 3 Flash ($1/1M audio tokens vs $3/1M for 2.5 Flash) - 3x cost savings
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
**Impact**: App unusable without internet on Android
**Mitigation**:
- Implement offline mode with local pitch detection library (TensorFlow Lite model)
- Cache scores locally with AsyncStorage/SQLite
- Download scores over WiFi for offline practice
- Show clear network status indicator
- Queue audio analysis requests when offline, sync when online
- Provide degraded experience: score viewing without real-time following

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
- [Gemini 3 Flash - Build with frontier intelligence](https://blog.google/technology/developers/build-with-gemini-3-flash/)
- [Gemini API Pricing](https://ai.google.dev/gemini-api/docs/pricing) - Gemini 3 Flash: $1/1M audio tokens (3x cheaper than 2.5 Flash)

### Audio-to-MIDI Tools
- [Building a GenAI-Powered Audio-to-MIDI Transcription Pipeline](https://medium.com/@bmonobina/building-a-genai-powered-audio-to-midi-transcription-pipeline-with-google-cloud-and-vertex-ai-90d910d2ec4c)
- [Google Gemini Music Generation | MIDI Agent](https://www.midiagent.com/google-gemini-music-generation)

### Music Rendering Libraries
- OpenSheetMusicDisplay: https://opensheetmusicdisplay.org/
- VexFlow: https://vexflow.com/
- ABCjs: https://www.abcjs.net/

### React Native & Android Development
- React Native Documentation: https://reactnative.dev/
- React Native Audio Libraries:
  - react-native-audio-record: https://github.com/goodatlas/react-native-audio-record
  - react-native-audio: https://github.com/jsierles/react-native-audio
- react-native-webview: https://github.com/react-native-webview/react-native-webview
- React Navigation: https://reactnavigation.org/
- Android Developer Guide: https://developer.android.com/
- Detox (E2E Testing): https://wix.github.io/Detox/

### Audio Processing
- Android AudioRecord API: https://developer.android.com/reference/android/media/AudioRecord
- Basic Pitch (Spotify): https://github.com/spotify/basic-pitch
- TensorFlow Lite for Audio: https://www.tensorflow.org/lite/examples/audio_classification/overview

### Similar Projects (for inspiration)
- Soundslice: https://www.soundslice.com/
- Flat.io: https://flat.io/
- MuseScore: https://musescore.org/

### Firebase & Backend
- Firebase for React Native: https://rnfirebase.io/
- Firebase Cloud Functions: https://firebase.google.com/docs/functions
- Google Cloud Run: https://cloud.google.com/run/docs

---

## Next Steps

1. **Review and approve this plan**
2. **Set up Android development environment**:
   - Install Android Studio
   - Install Java JDK 11+
   - Configure Android SDK (API 21-34)
   - Set up Android emulator or physical device
   - Install Node.js 18+ and npm
3. **Initialize React Native project**:
   ```bash
   npx react-native init Musically --template react-native-template-typescript
   cd Musically
   npm install
   ```
4. **Set up Firebase project**:
   - Create Firebase project in console
   - Enable Firestore, Storage, Authentication
   - Download google-services.json for Android
5. **Set up backend API**:
   - Create Node.js/Express server or Firebase Cloud Functions
   - Enable Gemini API in Google Cloud Console
   - Set up WebSocket server for real-time audio streaming
6. **Configure version control**:
   - Initialize git repository
   - Set up .gitignore (exclude API keys, google-services.json)
   - Create development, staging, production branches
7. **Establish CI/CD pipeline**:
   - GitHub Actions or GitLab CI for automated builds
   - Firebase App Distribution for beta testing
   - Automated testing on PR merge
8. **Begin Phase 1 implementation**

---

*This development plan is a living document and will be updated as the project evolves.*
