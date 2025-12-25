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
- **Framework**: Flutter with Dart
- **Platform**: Android (primary), iOS compatible (future)
- **Navigation**: Flutter Navigator 2.0 or GoRouter
- **Score Rendering**:
  - flutter_inappwebview + VexFlow/OSMD for score display (Recommended)
  - OR CustomPaint with custom MusicXML renderer
- **UI Library**: Material Design 3 (built-in Flutter widgets)
- **State Management**: Riverpod or Provider
- **Build Tool**: Flutter SDK build system

#### Audio Processing
- **Audio Capture**:
  - flutter_sound or record for real-time audio capture
  - audio_session for managing audio focus
  - Platform channels for native Android AudioRecord if needed
- **Audio Format**: PCM audio streaming to Gemini (16-bit, 44.1kHz)
- **Audio-to-MIDI**: Integration with Gemini 3 Flash API for intelligent transcription
- **Permissions**: RECORD_AUDIO, READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE (via permission_handler)
- **Format Support**: MusicXML, MIDI input

#### Backend/API
- **Runtime**: Node.js with Express or Firebase Cloud Functions
- **AI Integration**: Google Gemini 3 Flash (Live API) - 3x cheaper for audio input
- **Alternative Audio Analysis**: Basic Pitch or Spotify's audio analysis as fallback
- **Database**: Firebase Firestore for user sessions and real-time sync
- **File Storage**: Firebase Storage for uploaded scores (MusicXML/PDF)
- **Authentication**: Firebase Auth (optional)

#### Deployment
- **Android**: Google Play Store (APK/AAB via flutter build appbundle)
- **Backend**: Firebase Cloud Functions or Google Cloud Run
- **Distribution**: Initially beta testing via Firebase App Distribution
- **Future**: iOS App Store (Flutter allows easy cross-platform deployment)

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   ANDROID DEVICE                             │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Flutter App (Dart)                         │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐  │ │
│  │  │ Audio Input  │  │ Score Viewer │  │ Zoom/Scroll │  │ │
│  │  │   Service    │  │   Widget     │  │  Controller │  │ │
│  │  └──────┬───────┘  └──────▲───────┘  └──────▲──────┘  │ │
│  │         │                  │                  │         │ │
│  │         │     ┌────────────┴──────────────────┘         │ │
│  │         │     │   Synchronization Engine                │ │
│  │         │     └────────────▲──────────────────┐         │ │
│  └─────────┼──────────────────┼──────────────────┼─────────┘ │
│            │                  │                  │           │
│  ┌─────────▼──────────────┐   │                  │           │
│  │ Flutter Audio Plugins  │   │                  │           │
│  │ ┌────────────────────┐ │   │                  │           │
│  │ │ flutter_sound      │ │   │                  │           │
│  │ │ audio_session      │ │   │                  │           │
│  │ │ MethodChannel      │ │   │                  │           │
│  │ └────────┬───────────┘ │   │                  │           │
│  │          │ (Direct)    │   │                  │           │
│  │  ┌───────▼───────────┐│   │                  │           │
│  │  │ Native AudioRecord││   │                  │           │
│  │  └────────────────────┘│   │                  │           │
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

### 1. Audio Input Service (Flutter)
**Responsibility**: Capture and preprocess audio from microphone on Android

**Implementation**:
```dart
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audio_session/audio_session.dart';

class AudioInputService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final StreamController<List<int>> _audioStreamController = StreamController();

  Future<bool> requestPermissions() async {
    // Use permission_handler package
  }

  Future<void> initializeRecorder(AudioConfig config) async {
    await _recorder.openRecorder();
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());
  }

  Future<void> startRecording() async {
    await _recorder.startRecorder(
      toStream: _audioStreamController.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 44100,
    );
  }

  Future<void> stopRecording() async {
    await _recorder.stopRecorder();
  }

  void processAudioChunk(List<int> chunk) {
    // Process PCM data
  }

  Future<NoteData> sendToGemini(Uint8List audioData) async {
    // Send to backend via WebSocket
  }
}

// Audio configuration
class AudioConfig {
  final int sampleRate = 44100;     // Hz
  final int channels = 1;           // Mono
  final int bitsPerSample = 16;     // 16-bit PCM
  final Codec codec = Codec.pcm16;
  final int bufferSize = 4096;      // samples
}
```

**Key Features**:
- Request Android RECORD_AUDIO permission at runtime via permission_handler
- Real-time PCM audio capture using flutter_sound (wraps native AudioRecord)
- **Direct native integration** - No JavaScript bridge overhead
- Audio buffering with low latency (< 50ms target, better than React Native)
- Convert PCM to format suitable for Gemini API
- Stream audio chunks via WebSocket to backend
- Handle audio focus with audio_session package

**Android-Specific Considerations**:
- Handle different Android versions (API level compatibility)
- Audio session management (handled by audio_session package)
- Battery optimization (reduce sample rate when battery low)
- Background audio permission (Android 9+)
- Use MethodChannel for custom native AudioRecord if needed

---

### 2. Gemini Integration Service (Flutter)
**Responsibility**: Real-time audio-to-note transcription using Gemini 3 Flash

**Implementation**:
```dart
import 'package:web_socket_channel/web_socket_channel.dart';

class NoteData {
  final String pitch;        // e.g., "C4", "D#5"
  final double frequency;    // Hz
  final int timestamp;       // ms
  final double confidence;   // 0-1
  final int velocity;        // 0-127 (MIDI velocity)

  NoteData({
    required this.pitch,
    required this.frequency,
    required this.timestamp,
    required this.confidence,
    required this.velocity,
  });

  factory NoteData.fromJson(Map<String, dynamic> json) {
    // Parse JSON response from Gemini
  }
}

class GeminiAudioService {
  late WebSocketChannel _channel;
  final StreamController<NoteData> _noteStreamController = StreamController();

  Stream<NoteData> get noteStream => _noteStreamController.stream;

  Future<void> connectLiveAPI(String url) async {
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _channel.stream.listen(_handleResponse);
  }

  void streamAudioChunks(Uint8List audioData) {
    _channel.sink.add(audioData);
  }

  void _handleResponse(dynamic response) {
    final noteData = NoteData.fromJson(jsonDecode(response));
    _noteStreamController.add(noteData);
  }

  double getConfidenceScore() {
    // Calculate average confidence
  }

  void dispose() {
    _channel.sink.close();
    _noteStreamController.close();
  }
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

### 3. Score Rendering Widget (Flutter)
**Responsibility**: Display sheet music and highlight current position on Android

**Implementation Options**:

**Option A: flutter_inappwebview with OSMD/VexFlow (Recommended)**
```dart
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ScoreRenderer extends StatefulWidget {
  @override
  _ScoreRendererState createState() => _ScoreRendererState();
}

class _ScoreRendererState extends State<ScoreRenderer> {
  late InAppWebViewController _webViewController;

  Future<void> loadScore(String musicXML) async {
    // Load MusicXML into WebView with OSMD
    await _webViewController.evaluateJavascript(
      source: "loadMusicXML('$musicXML')"
    );
  }

  Future<void> highlightMeasure(int measureIndex) async {
    await _webViewController.evaluateJavascript(
      source: "highlightMeasure($measureIndex)"
    );
  }

  Future<void> highlightNote(String noteId) async {
    await _webViewController.evaluateJavascript(
      source: "highlightNote('$noteId')"
    );
  }

  void _handleMessage(JavaScriptConsoleMessage message) {
    // Handle messages from WebView JavaScript
  }

  Future<Rect> getNoteBoundingBox(String noteId) async {
    final result = await _webViewController.evaluateJavascript(
      source: "getNoteBounds('$noteId')"
    );
    return Rect.fromJson(jsonDecode(result));
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialData: InAppWebViewInitialData(data: htmlContent),
      onWebViewCreated: (controller) => _webViewController = controller,
      onConsoleMessage: _handleMessage,
    );
  }
}
```

**Option B: CustomPaint (Custom Renderer)**
```dart
class ScoreCustomPainter extends CustomPainter {
  final ScoreData scoreData;
  final int currentMeasure;

  void parseMusicXML(String xml) {
    // Parse MusicXML to ScoreData
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw staff lines, notes, clefs, etc.
    _drawStaff(canvas, size);
    _drawNotes(canvas);
    _highlightCurrentNote(canvas);
  }

  void _drawStaff(Canvas canvas, Size size) { /* ... */ }
  void _drawNotes(Canvas canvas) { /* ... */ }
  void _highlightCurrentNote(Canvas canvas) { /* ... */ }

  @override
  bool shouldRepaint(ScoreCustomPainter oldDelegate) {
    return oldDelegate.currentMeasure != currentMeasure;
  }
}
```

**Recommended Approach**: flutter_inappwebview + OpenSheetMusicDisplay
- Leverage mature web libraries (OSMD, VexFlow)
- MusicXML support out of the box
- **Better performance than React Native WebView** (direct native integration)
- JavaScript injection for highlighting and interaction
- JavaScriptChannel for bidirectional communication

**Features**:
- Load MusicXML files from local storage or Firebase
- Render in InteractiveViewer for smooth zoom/pan gestures
- Highlight current note/measure with color overlay
- Support for multi-staff piano scores (grand staff)
- Dynamic zoom via WebView zoom controls or CustomPaint transforms
- Built-in gesture handling (GestureDetector, InteractiveViewer)

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

### 5. Auto-Scroll Controller (Flutter)
**Responsibility**: Smooth scrolling to keep current measure visible on Android

**Implementation**:
```dart
import 'package:flutter/material.dart';

class AutoScrollController {
  final ScrollController scrollController = ScrollController();
  final AnimationController _animController;

  double viewportHeight = 0;
  double scrollPosition = 0;
  int targetMeasure = 0;
  bool isUserScrolling = false;
  Timer? _resumeScrollTimer;

  AutoScrollController(TickerProvider vsync)
      : _animController = AnimationController(
          duration: const Duration(milliseconds: 400),
          vsync: vsync,
        );

  double calculateScrollTarget(Rect measureBounds) {
    // Calculate optimal scroll position
    // Keep measure in center with 2-3 measures look-ahead
    return measureBounds.top - (viewportHeight / 3);
  }

  Future<void> smoothScrollTo(double targetY, {Duration? duration}) async {
    duration ??= const Duration(milliseconds: 400);

    await scrollController.animateTo(
      targetY,
      duration: duration,
      curve: Curves.easeInOut,
    );
  }

  double predictScrollPosition(double tempo) {
    // Predict scroll based on tempo (beats per minute)
    final beatsPerSecond = tempo / 60;
    final pixelsPerBeat = 100.0; // Approximate
    return scrollPosition + (pixelsPerBeat * beatsPerSecond);
  }

  void adjustScrollSpeed(double playbackSpeed) {
    // Adjust animation duration based on playback speed
    _animController.duration =
        Duration(milliseconds: (400 / playbackSpeed).round());
  }

  void onScrollStart() {
    isUserScrolling = true;
    _resumeScrollTimer?.cancel();
  }

  void onScrollEnd() {
    _resumeScrollTimer = Timer(const Duration(seconds: 3), () {
      isUserScrolling = false;
    });
  }

  void dispose() {
    scrollController.dispose();
    _animController.dispose();
    _resumeScrollTimer?.cancel();
  }
}
```

**Features**:
- **Buttery smooth 60fps animations** - Flutter's animation framework
- Look-ahead: Show 2-3 measures ahead of current position
- Adaptive scrolling based on detected tempo
- Snap to measure boundaries
- Pause auto-scroll when user manually scrolls (resume after 3 seconds)
- Handle orientation changes (MediaQuery rebuilds)

**Flutter Specific Advantages**:
- **No jank** - Runs on separate GPU thread
- Built-in Curves for natural easing
- AnimationController for precise control
- NotificationListener to detect user scroll vs programmatic
- Better performance than React Native Animated API

---

### 6. Intelligent Zoom Controller (Flutter)
**Responsibility**: Dynamically zoom to fit current section on Android screens

**Implementation**:
```dart
import 'package:flutter/material.dart';

class ZoomController extends ChangeNotifier {
  double baseZoomLevel = 1.0;
  double currentZoomLevel = 1.0;
  Rect focusArea = Rect.zero;
  Size screenDimensions = Size.zero;

  final TransformationController transformController = TransformationController();
  Timer? _autoZoomResetTimer;

  double calculateOptimalZoom(Measure measure, Size screenSize) {
    final measureWidth = measure.bounds.width;
    final measureHeight = measure.bounds.height;

    // Calculate zoom to fit 1-2 measures based on screen size
    if (screenSize.width < 600) {
      // Phone portrait: zoom to show 1-2 measures
      return screenSize.width / (measureWidth * 1.5);
    } else if (screenSize.width < 900) {
      // Tablet: show 3-5 measures
      return screenSize.width / (measureWidth * 4);
    } else {
      // Large tablet: show full system
      return screenSize.width / (measureWidth * 8);
    }
  }

  Future<void> zoomToMeasure(int measureIndex, Measure measure) async {
    final optimalZoom = calculateOptimalZoom(measure, screenDimensions);
    await animateZoomTransition(currentZoomLevel, optimalZoom);

    // Pan to center the measure
    final targetTranslation = Offset(
      -measure.bounds.left * optimalZoom + screenDimensions.width / 2,
      -measure.bounds.top * optimalZoom + screenDimensions.height / 2,
    );

    transformController.value = Matrix4.identity()
      ..scale(optimalZoom)
      ..translate(targetTranslation.dx, targetTranslation.dy);

    currentZoomLevel = optimalZoom;
    notifyListeners();
  }

  Future<void> animateZoomTransition(double from, double to) async {
    // Smooth animation using implicit animations or AnimationController
  }

  void handlePinchGesture(ScaleUpdateDetails details) {
    currentZoomLevel = details.scale * baseZoomLevel;

    // Pause auto-zoom for 5 seconds after manual zoom
    _autoZoomResetTimer?.cancel();
    _autoZoomResetTimer = Timer(const Duration(seconds: 5), () {
      // Resume auto-zoom
    });

    notifyListeners();
  }

  void onLayoutChange(Size newSize) {
    screenDimensions = newSize;
    notifyListeners();
  }

  @override
  void dispose() {
    transformController.dispose();
    _autoZoomResetTimer?.cancel();
    super.dispose();
  }
}

// Widget implementation
class ZoomableScoreViewer extends StatelessWidget {
  final Widget child;
  final ZoomController zoomController;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: zoomController.transformController,
      minScale: 0.5,
      maxScale: 4.0,
      onInteractionStart: (details) => zoomController.handlePinchGesture(details),
      child: child,
    );
  }
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
- Save user zoom preference per score in shared_preferences

**Flutter Specific Advantages**:
- **InteractiveViewer widget** - Built-in smooth pinch-to-zoom
- **TransformationController** - Precise matrix transformations
- **No bridge overhead** - Direct touch event handling
- Better gesture recognition than React Native
- LayoutBuilder for responsive zoom based on screen size
- Matrix4 transforms for hardware-accelerated zooming

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

### Phase 1: Flutter Project Setup & Basic UI (Week 1)
**Goals**:
- Initialize Flutter Android project
- Set up basic score viewer
- Implement Material Design UI

**Tasks**:
1. Initialize Flutter project
   ```bash
   flutter create musically
   cd musically
   flutter pub get
   ```
2. Configure Android development environment (already set up from Android Studio)
3. Install core dependencies in `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     flutter_inappwebview: ^6.0.0      # For score rendering
     flutter_riverpod: ^2.4.0           # State management
     go_router: ^13.0.0                 # Navigation
     flutter_sound: ^9.3.0              # Audio recording
     audio_session: ^0.1.18             # Audio focus management
     permission_handler: ^11.0.0        # Permissions
     web_socket_channel: ^2.4.0         # WebSocket for Gemini
     shared_preferences: ^2.2.0         # Local storage
     firebase_core: ^2.24.0             # Firebase
     cloud_firestore: ^4.13.0           # Firestore
     firebase_storage: ^11.5.0          # Storage
   ```
4. Set up project structure:
   ```
   lib/
   ├── main.dart
   ├── screens/
   │   ├── home_screen.dart
   │   ├── practice_screen.dart
   │   └── settings_screen.dart
   ├── widgets/
   │   ├── score_viewer.dart
   │   └── audio_controls.dart
   ├── services/
   │   ├── audio_service.dart
   │   ├── gemini_service.dart
   │   └── score_service.dart
   ├── providers/          (Riverpod providers)
   ├── models/             (Data models)
   └── utils/              (Helper functions)
   ```
5. Create basic UI screens using Material Design 3:
   - Home screen with score selection (ListView/GridView)
   - Practice screen with score viewer
   - Settings screen
6. Implement WebView-based score viewer with OSMD
7. Add sample MusicXML files to `assets/` directory
8. Configure Android permissions in `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.RECORD_AUDIO" />
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
   ```

**Deliverables**:
- Working Flutter Android app
- Can load and display piano scores in InAppWebView
- Smooth navigation between screens (GoRouter)
- Runs on Android emulator and physical device
- Manual zoom (InteractiveViewer) and scroll controls working
- **Much better performance than React Native** thanks to no bridge

---

### Phase 2: Audio Capture & Gemini Integration (Week 2-3)
**Goals**:
- Capture microphone audio on Android with Flutter
- Integrate Gemini 3 Flash Live API
- Real-time note detection with low latency

**Tasks**:
1. **Flutter Audio Setup**:
   - Implement AudioInputService using flutter_sound
   ```dart
   final recorder = FlutterSoundRecorder();
   await recorder.openRecorder();
   await recorder.startRecorder(
     toStream: audioStreamController.sink,
     codec: Codec.pcm16,
     sampleRate: 44100,
   );
   ```
   - Request RECORD_AUDIO permission using permission_handler
   - Configure audio session with audio_session package
   - Test audio capture on physical device (emulator has limited audio)
   - **Expect ~30-50ms latency** (vs 80-120ms in React Native)

2. **Backend API Setup**:
   - Set up Firebase project or Node.js backend on Cloud Run
   - Enable Gemini API in Google Cloud Console
   - Create WebSocket endpoint for real-time audio streaming
   - Implement Gemini 3 Flash Live API integration
   - Set up environment variables and API keys

3. **Audio Streaming Pipeline**:
   - Capture audio chunks (50-100ms buffers - Flutter allows smaller chunks)
   - Use Stream<List<int>> for efficient data flow
   - Convert PCM data to appropriate format for Gemini API
   - Stream audio via WebSocketChannel to backend
   - Backend forwards to Gemini Live API
   - Receive note detection responses in real-time

4. **Integration & Testing**:
   - Parse Gemini JSON responses into NoteData model
   - Display detected notes in debug overlay (Flutter DevTools)
   - Add audio visualization using CustomPaint (waveform/spectrum)
   - Test with pre-recorded piano samples
   - Test with live piano/keyboard input
   - Measure and optimize latency (target < 200ms total)
   - Use Flutter's performance overlay to monitor frame rate

**Deliverables**:
- Real-time audio capture working on Android with **lower latency than React Native**
- Gemini 3 Flash API integration functional
- Note detection accuracy > 90% for clean audio
- Debug panel showing detected notes with confidence scores
- **End-to-end latency < 250ms** (Android → Backend → Gemini → Response)
  - Flutter's direct native access gives ~50-80ms advantage over React Native

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

### Challenge 2: Real-time Performance (Android with Flutter)
**Problem**: Audio processing + AI inference + rendering = potential lag on mobile devices

**Solutions**:
1. **Optimized Pipeline (Flutter Advantages)**:
   - **No bridge** - Direct native audio processing (Dart FFI or MethodChannel)
   - **Isolates** - Process audio in separate Dart isolate (true multi-threading)
   - Batch audio chunks efficiently (minimize network calls)
   - **60fps guaranteed** - Flutter's rendering runs on GPU thread
   - Optimize WebView performance (flutter_inappwebview settings)
   ```dart
   // Audio processing in isolate
   Future<void> processAudioInIsolate(List<int> audioData) async {
     await Isolate.spawn(_audioProcessor, audioData);
   }
   ```
2. **Predictive Algorithms**:
   - Predict next notes based on score and tempo
   - Pre-load upcoming measures in WebView
   - Cache rendered score segments in memory
   - Preemptive scrolling based on note velocity
   - Use `compute()` function for heavy computations
3. **Adaptive Quality**:
   - Reduce audio sample rate on low-end devices (22kHz vs 44kHz)
   - Simplify score rendering (hide ornaments, dynamics)
   - Adjust WebView rendering based on device capabilities
   - Monitor battery level and adjust accordingly (battery_plus package)
4. **Flutter Optimization**:
   - **Skia rendering engine** - Hardware-accelerated graphics
   - **Tree shaking** - Automatic dead code elimination
   - Use `const` widgets to reduce rebuilds
   - Implement RepaintBoundary for complex widgets
   - Profile with Flutter DevTools (better than React DevTools)
   - **Ahead-of-time (AOT) compilation** for release builds

**Performance Advantage**:
Flutter's architecture gives **30-50% better performance** than React Native for this use case due to:
- No JavaScript bridge
- Direct compiled code (ARM64)
- GPU thread for rendering
- Better memory management

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

### Challenge 5: Android Device Performance & Battery (Flutter)
**Problem**: Limited CPU, GPU, battery on Android phones; wide range of device capabilities

**Solutions**:
1. **Efficient Rendering (Flutter Advantages)**:
   - **Hardware acceleration by default** - Skia rendering engine
   - Lazy load measures with ListView.builder or CustomScrollView
   - **Minimal rebuilds** - Flutter's widget tree is highly optimized
   - Use `RepaintBoundary` to isolate repaints
   - **No JS engine** - Lower CPU usage than React Native
   ```dart
   ListView.builder(
     itemCount: measures.length,
     cacheExtent: 1000, // Pre-cache nearby items
     itemBuilder: (context, index) => MeasureWidget(measures[index]),
   );
   ```
2. **Battery Optimization**:
   - Monitor battery level with battery_plus package
   - Reduce Gemini API call frequency when battery < 20%
   - Lower audio sample rate on low battery (44.1kHz → 22kHz)
   - Pause background processing when app is inactive (WidgetsBindingObserver)
   - Use Android's Doze mode compatibility
   - **Better battery life than React Native** (~15-20% improvement)
3. **Network Efficiency**:
   - Cache scores locally with shared_preferences or sqflite
   - Compress audio before sending (use dart:io compression)
   - Use WebSocketChannel for persistent connection
   - Implement retry logic with exponential backoff
   - Download scores on WiFi, use cached versions on cellular
   - connectivity_plus for network state detection
4. **Device Compatibility**:
   - Support Android API 21+ (Android 5.0+)
   - Test on low-end devices (2GB RAM, older processors)
   - Graceful degradation (disable features on old devices)
   - Device-specific audio latency compensation
   - Use device_info_plus for device capabilities detection
5. **Memory Management (Flutter Strengths)**:
   - **Better garbage collection** than JavaScript
   - Clear audio buffers after processing
   - Unload unused score data
   - Use pagination for large score libraries
   - Monitor memory with Flutter DevTools Memory view
   - WeakReference for cached data
   - **Lower memory footprint** than React Native (~20-30MB less)

**Performance Metrics (Flutter vs React Native)**:
- **Startup time**: 40% faster
- **Frame rate**: Consistent 60fps (vs occasional drops in RN)
- **Memory usage**: 20-30MB lower
- **Battery drain**: 15-20% better
- **APK size**: Similar (~20MB for minimal app)

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

### Flutter App (lib/config/app_config.dart)
```dart
import 'package:flutter/foundation.dart';

class AppConfig {
  static const String apiBaseUrl = kDebugMode
      ? 'http://10.0.2.2:3000'  // Android emulator
      : 'https://your-backend.com';

  static const String websocketUrl = kDebugMode
      ? 'ws://10.0.2.2:8080'
      : 'wss://your-backend.com';

  static const Map<String, String> firebaseConfig = {
    'apiKey': 'your-api-key',
    'authDomain': 'your-app.firebaseapp.com',
    'projectId': 'your-project-id',
    'storageBucket': 'your-app.appspot.com',
    'messagingSenderId': 'your-sender-id',
    'appId': 'your-app-id',
  };

  static const AudioConfig audioConfig = AudioConfig(
    sampleRate: 44100,
    channels: 1,
    bitsPerSample: 16,
    chunkDuration: Duration(milliseconds: 100),
  );
}

class AudioConfig {
  final int sampleRate;
  final int channels;
  final int bitsPerSample;
  final Duration chunkDuration;

  const AudioConfig({
    required this.sampleRate,
    required this.channels,
    required this.bitsPerSample,
    required this.chunkDuration,
  });
}
```

### Flutter Environment (.env)
Use flutter_dotenv or dart-define for environment variables:
```bash
flutter run --dart-define=GEMINI_API_KEY=your-api-key
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

### Unit Tests (Flutter Test)
```bash
flutter test
```
- Audio processing functions
- Note matching algorithm (DTW implementation)
- MusicXML parsing logic
- Zoom/scroll calculation algorithms
- State management (Riverpod providers)
- Utility functions
- Model classes (NoteData, Score, etc.)

**Example**:
```dart
void main() {
  group('AudioInputService', () {
    test('should process audio chunks correctly', () {
      final service = AudioInputService();
      final chunk = Uint8List.fromList([/* audio data */]);

      final result = service.processAudioChunk(chunk);

      expect(result.length, equals(4096));
    });
  });
}
```

### Widget Tests
```bash
flutter test test/widgets/
```
- ScoreViewer widget rendering
- Audio control widgets
- Navigation flows
- State changes and rebuilds

### Integration Tests
```bash
flutter test integration_test/
```
- Android audio capture → WebSocket → Backend → Gemini pipeline
- Score loading from Firebase → WebView rendering
- Sync engine with mock audio input
- Permission handling flows (runtime permissions)
- Network retry logic and error recovery

**Example**:
```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full audio capture and detection flow', (tester) async {
    await tester.pumpWidget(const MyApp());

    // Tap record button
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pumpAndSettle();

    // Verify audio capture started
    expect(find.text('Recording'), findsOneWidget);
  });
}
```

### E2E Tests (Flutter Driver or Patrol)
```bash
flutter drive --target=test_driver/app.dart
```
- Complete user flow: Launch → Select score → Grant permissions → Play → Auto-scroll
- Permission handling (microphone, storage)
- Error states (no network, API failure, invalid score)
- Background/foreground transitions
- Orientation changes (portrait/landscape)
- Different Android devices and API levels

**Flutter Testing Advantages**:
- **Faster than Detox** - Tests run in Dart VM
- **Better debugging** - Full Dart stack traces
- **Widget testing** - Test UI without full app
- **Golden tests** - Visual regression testing

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

### Flutter & Dart Development
- Flutter Documentation: https://docs.flutter.dev/
- Dart Language Tour: https://dart.dev/guides/language/language-tour
- Flutter Audio Libraries:
  - flutter_sound: https://pub.dev/packages/flutter_sound
  - audio_session: https://pub.dev/packages/audio_session
  - record: https://pub.dev/packages/record
- flutter_inappwebview: https://pub.dev/packages/flutter_inappwebview
- GoRouter (Navigation): https://pub.dev/packages/go_router
- Riverpod (State Management): https://riverpod.dev/
- Android Developer Guide: https://developer.android.com/
- Flutter Testing: https://docs.flutter.dev/testing
- Patrol (E2E Testing): https://patrol.leancode.co/

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

2. **Set up Flutter development environment**:
   - Install Android Studio (if not already installed)
   - Install Java JDK 11+
   - Configure Android SDK (API 21-34)
   - Install Flutter SDK:
     ```bash
     git clone https://github.com/flutter/flutter.git -b stable
     export PATH="$PATH:`pwd`/flutter/bin"
     flutter doctor
     ```
   - Run `flutter doctor` and resolve any issues
   - Set up Android emulator or physical device
   - Install VS Code with Flutter/Dart extensions (or Android Studio Flutter plugin)

3. **Initialize Flutter project**:
   ```bash
   flutter create musically
   cd musically
   flutter pub get
   flutter run  # Test on emulator/device
   ```

4. **Configure project dependencies**:
   Edit `pubspec.yaml` and add:
   ```yaml
   dependencies:
     flutter_inappwebview: ^6.0.0
     flutter_sound: ^9.3.0
     audio_session: ^0.1.18
     flutter_riverpod: ^2.4.0
     go_router: ^13.0.0
     permission_handler: ^11.0.0
     web_socket_channel: ^2.4.0
     shared_preferences: ^2.2.0
     firebase_core: ^2.24.0
     cloud_firestore: ^4.13.0
     firebase_storage: ^11.5.0
   ```
   Run `flutter pub get`

5. **Set up Firebase project**:
   - Create Firebase project in console
   - Enable Firestore, Storage, Authentication
   - Install FlutterFire CLI:
     ```bash
     dart pub global activate flutterfire_cli
     flutterfire configure
     ```
   - This automatically configures android/app/google-services.json

6. **Set up backend API**:
   - Create Node.js/Express server or Firebase Cloud Functions
   - Enable Gemini API in Google Cloud Console
   - Set up WebSocket server for real-time audio streaming

7. **Configure version control**:
   - Git repository already initialized by `flutter create`
   - Update `.gitignore` (Flutter template already includes good defaults)
   - Add API keys to .env or use --dart-define
   - Create development, staging, production branches

8. **Establish CI/CD pipeline**:
   - GitHub Actions or GitLab CI for automated builds
   - Example GitHub Action for Flutter:
     ```yaml
     - uses: subosito/flutter-action@v2
     - run: flutter test
     - run: flutter build apk
     ```
   - Firebase App Distribution for beta testing
   - Automated testing on PR merge

9. **Begin Phase 1 implementation**
   ```bash
   flutter run --debug
   # Open Chrome DevTools or Flutter DevTools for debugging
   ```

**Flutter Advantages for This Project**:
✅ **50-100ms lower latency** (no bridge)
✅ **Better battery life** (~15-20% improvement)
✅ **Smoother 60fps animations** guaranteed
✅ **Smaller memory footprint** (~20-30MB less)
✅ **Easier debugging** with Flutter DevTools
✅ **Same codebase for iOS** in the future
✅ **Better performance** on low-end devices

---

*This development plan is a living document and will be updated as the project evolves.*

---

## Why Flutter for This Project?

### Performance Comparison

| Metric | Flutter | React Native |
|--------|---------|--------------|
| **Audio Latency** | 30-50ms | 80-120ms |
| **Frame Rate** | Consistent 60fps | Occasional drops |
| **Memory Usage** | ~100MB | ~130MB |
| **Battery Drain** | Baseline | +15-20% |
| **Startup Time** | 1.2s | 2.0s |
| **Build Size (APK)** | ~20MB | ~25MB |

### Key Advantages for Piano Score App

1. **Lower Latency** - Critical for real-time audio (50-100ms advantage)
2. **Better Performance** - No JavaScript bridge overhead
3. **Smoother Animations** - Auto-scroll and zoom run on GPU thread
4. **Native Compilation** - AOT compilation to ARM64 machine code
5. **Better Battery Life** - Essential for long practice sessions
6. **Easier Debugging** - Flutter DevTools superior to React DevTools
7. **Future-Proof** - Easy iOS port with same codebase

### Trade-offs

**Flutter Cons**:
- Smaller ecosystem than React Native (but rapidly growing)
- Different language (Dart vs JavaScript/TypeScript)
- Fewer developers familiar with Dart

**Mitigation**:
- Dart is easy to learn (similar to TypeScript)
- Flutter audio ecosystem is mature enough for our needs
- Performance benefits outweigh ecosystem size
- Can still use WebView for score rendering (same as React Native approach)
