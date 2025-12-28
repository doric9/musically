import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../providers/audio_providers.dart';
import '../models/score.dart';
import '../models/note_data.dart';
import '../widgets/score_viewer.dart';
import '../widgets/stats_widgets.dart';
import '../services/score_sync_service.dart';
import '../services/practice_stats_service.dart';
import '../controllers/zoom_controller.dart';
import '../controllers/auto_scroll_controller.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen>
    with TickerProviderStateMixin {
  Score? _score;
  bool _isScoreLoaded = false;
  bool _isInitialized = false;

  // Controllers
  late ZoomController _zoomController;
  AutoScrollController? _scrollController;
  ScoreSyncService? _syncService;
  PracticeStatsService? _statsService;

  // UI state
  bool _autoScrollEnabled = true;
  ScorePosition _currentPosition = ScorePosition.initial();
  final GlobalKey<State<ScoreViewer>> _scoreViewerKey = GlobalKey();
  bool _showSessionSummary = false;

  @override
  void initState() {
    super.initState();
    _zoomController = ZoomController(initialZoom: 1.0);
    _initializeServices();
    _loadScore();
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _scrollController?.dispose();
    _statsService?.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      final audioService = ref.read(audioInputServiceProvider);
      final geminiService = ref.read(geminiAudioServiceProvider);

      // Request microphone permission
      final hasPermission = await audioService.requestPermissions();

      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is required'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Initialize audio service
      await audioService.initialize();

      // Connect to Gemini API (mock mode for development)
      await geminiService.connectLiveAPI();

      setState(() {
        _isInitialized = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio system initialized')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Initialization failed: $e')),
        );
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (!_isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for initialization...')),
      );
      return;
    }

    final audioService = ref.read(audioInputServiceProvider);
    final isRecording = ref.read(isRecordingProvider);

    try {
      if (isRecording) {
        await audioService.stopRecording();
        ref.read(isRecordingProvider.notifier).state = false;

        // End stats session and show summary
        _statsService?.endSession();
        setState(() {
          _showSessionSummary = true;
        });
      } else {
        await audioService.startRecording();
        ref.read(isRecordingProvider.notifier).state = true;

        // Start stats session
        _statsService?.startSession();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording error: $e')),
        );
      }
    }
  }

  Future<void> _loadScore() async {
    try {
      // Load sample MusicXML file from assets
      final musicXmlContent = await rootBundle.loadString(
        'assets/scores/sample.musicxml',
      );

      // Create sample score with metadata
      // Note: In production, this would parse the MusicXML to extract measures and notes
      final score = Score(
        id: 'sample-001',
        title: 'Twinkle Twinkle Little Star',
        composer: 'Traditional',
        musicXmlContent: musicXmlContent,
        measures: _createSampleMeasures(), // Mock measures for synchronization
        totalDuration: 32000, // 32 seconds
        difficulty: 'Beginner',
      );

      setState(() {
        _score = score;
        _isScoreLoaded = true;

        // Initialize synchronization service
        _syncService = ScoreSyncService(score: score);

        // Initialize statistics service
        _statsService = PracticeStatsService(score: score);

        // Initialize scroll controller
        _scrollController = AutoScrollController(
          score: score,
          scoreViewerKey: _scoreViewerKey,
        );
        _scrollController!.setEnabled(_autoScrollEnabled);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Score loaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load score: $e')),
        );
      }
    }
  }

  /// Create sample measures for synchronization
  /// In production, this would be parsed from MusicXML
  List<Measure> _createSampleMeasures() {
    return [
      Measure(
        index: 0,
        startTime: 0,
        duration: 8000,
        timeSignature: '4/4',
        keySignature: 'C major',
        tempo: 120,
        notes: [
          ScoreNote(pitch: 'C4', midiNumber: 60, startTime: 0, duration: 1000, noteType: 'quarter'),
          ScoreNote(pitch: 'C4', midiNumber: 60, startTime: 1000, duration: 1000, noteType: 'quarter'),
          ScoreNote(pitch: 'G4', midiNumber: 67, startTime: 2000, duration: 1000, noteType: 'quarter'),
          ScoreNote(pitch: 'G4', midiNumber: 67, startTime: 3000, duration: 1000, noteType: 'quarter'),
        ],
      ),
      Measure(
        index: 1,
        startTime: 8000,
        duration: 8000,
        timeSignature: '4/4',
        notes: [
          ScoreNote(pitch: 'A4', midiNumber: 69, startTime: 0, duration: 1000, noteType: 'quarter'),
          ScoreNote(pitch: 'A4', midiNumber: 69, startTime: 1000, duration: 1000, noteType: 'quarter'),
          ScoreNote(pitch: 'G4', midiNumber: 67, startTime: 2000, duration: 2000, noteType: 'half'),
        ],
      ),
      Measure(
        index: 2,
        startTime: 16000,
        duration: 8000,
        timeSignature: '4/4',
        notes: [
          ScoreNote(pitch: 'F4', midiNumber: 65, startTime: 0, duration: 1000, noteType: 'quarter'),
          ScoreNote(pitch: 'F4', midiNumber: 65, startTime: 1000, duration: 1000, noteType: 'quarter'),
          ScoreNote(pitch: 'E4', midiNumber: 64, startTime: 2000, duration: 1000, noteType: 'quarter'),
          ScoreNote(pitch: 'E4', midiNumber: 64, startTime: 3000, duration: 1000, noteType: 'quarter'),
        ],
      ),
      Measure(
        index: 3,
        startTime: 24000,
        duration: 8000,
        timeSignature: '4/4',
        notes: [
          ScoreNote(pitch: 'D4', midiNumber: 62, startTime: 0, duration: 1000, noteType: 'quarter'),
          ScoreNote(pitch: 'D4', midiNumber: 62, startTime: 1000, duration: 1000, noteType: 'quarter'),
          ScoreNote(pitch: 'C4', midiNumber: 60, startTime: 2000, duration: 2000, noteType: 'half'),
        ],
      ),
    ];
  }

  /// Handle detected note and update synchronization
  void _onNoteDetected(NoteData note) {
    if (_syncService == null || !_isScoreLoaded || _score == null) return;

    final newPosition = _syncService!.processDetectedNote(note);

    // Record statistics
    if (_statsService != null && _statsService!.isActive) {
      final currentMeasure = _score!.getMeasure(newPosition.measureIndex);
      final expectedNote = currentMeasure?.getNote(newPosition.noteIndex);

      if (expectedNote != null) {
        _statsService!.recordPlayedNote(
          expectedNote: expectedNote,
          playedNote: note,
          position: newPosition,
          syncConfidence: _syncService!.getSynchronizationConfidence(),
        );
      }
    }

    setState(() {
      _currentPosition = newPosition;
    });

    // Update scroll position
    if (_autoScrollEnabled) {
      _scrollController?.updatePosition(newPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = ref.watch(isRecordingProvider);
    final latestNote = ref.watch(latestNoteProvider);
    final detectedNotes = ref.watch(audioStreamNotifierProvider);

    // Listen to note stream and trigger synchronization
    ref.listen<AsyncValue>(latestNoteProvider, (previous, next) {
      next.whenData((note) {
        if (note != null) {
          _onNoteDetected(note);
        }
      });
    });

    // Show session summary dialog
    if (_showSessionSummary && _statsService != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            child: SessionSummaryCard(
              stats: _statsService!.currentSession,
              onRetry: () {
                Navigator.of(context).pop();
                setState(() {
                  _showSessionSummary = false;
                });
                _syncService?.reset();
                _scrollController?.reset();
                _statsService?.reset();
                setState(() {
                  _currentPosition = ScorePosition.initial();
                });
              },
              onClose: () {
                Navigator.of(context).pop();
                setState(() {
                  _showSessionSummary = false;
                });
              },
            ),
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_score?.title ?? 'Practice Session'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          if (_isScoreLoaded)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  'Measure ${_currentPosition.measureIndex + 1}/${_score?.measureCount ?? 0}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Score Viewer Area
          Expanded(
            child: Container(
              color: Colors.white,
              child: _isScoreLoaded && _score != null
                  ? Stack(
                      children: [
                        // Score Viewer with OSMD
                        AnimatedBuilder(
                          animation: _zoomController,
                          builder: (context, child) {
                            return ScoreViewer(
                              key: _scoreViewerKey,
                              score: _score!,
                              currentPosition: _currentPosition,
                              zoom: _zoomController.zoom,
                              onError: (error) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Score error: $error')),
                                );
                              },
                            );
                          },
                        ),

                        // Zoom controls overlay
                        Positioned(
                          top: 16,
                          right: 16,
                          child: AnimatedBuilder(
                            animation: _zoomController,
                            builder: (context, child) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove,
                                          color: Colors.white, size: 18),
                                      onPressed: _zoomController.zoomOut,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                    ),
                                    Text(
                                      _zoomController.getZoomPercentage(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add,
                                          color: Colors.white, size: 18),
                                      onPressed: _zoomController.zoomIn,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        // Real-time stats panel
                        if (_statsService != null && isRecording)
                          Positioned(
                            top: 16,
                            left: 16,
                            child: AnimatedBuilder(
                              animation: _statsService!,
                              builder: (context, child) {
                                return RealtimeStatsPanel(
                                  stats: _statsService!.currentSession,
                                  compact: true,
                                );
                              },
                            ),
                          ),

                        // Debug: Show detected notes
                        if (isRecording)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: _buildDebugNotesPanel(latestNote, detectedNotes),
                          ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.music_note_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Loading score...',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const CircularProgressIndicator(),
                        ],
                      ),
                    ),
            ),
          ),

          // Control Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Recording Status
                  if (isRecording)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Recording...',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Initialization Status
                  if (!_isInitialized)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Initializing audio system...'),
                        ],
                      ),
                    ),

                  // Main Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Reset Button
                      IconButton.outlined(
                        icon: const Icon(Icons.replay),
                        onPressed: _isScoreLoaded
                            ? () {
                                _syncService?.reset();
                                _scrollController?.reset();
                                setState(() {
                                  _currentPosition = ScorePosition.initial();
                                });
                              }
                            : null,
                        tooltip: 'Reset to beginning',
                      ),

                      // Record/Stop Button
                      FloatingActionButton.large(
                        onPressed: _toggleRecording,
                        backgroundColor:
                            isRecording ? Colors.red : Colors.blue,
                        child: Icon(
                          isRecording ? Icons.stop : Icons.mic,
                          size: 32,
                        ),
                      ),

                      // Auto-scroll Toggle
                      IconButton.filled(
                        icon: Icon(
                          _autoScrollEnabled
                              ? Icons.auto_awesome
                              : Icons.auto_awesome_outlined,
                        ),
                        onPressed: _isScoreLoaded
                            ? () {
                                setState(() {
                                  _autoScrollEnabled = !_autoScrollEnabled;
                                  _scrollController?.setEnabled(_autoScrollEnabled);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Auto-scroll ${_autoScrollEnabled ? "enabled" : "disabled"}',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            : null,
                        tooltip: 'Toggle auto-scroll',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugNotesPanel(AsyncValue latestNote, List detectedNotes) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.black.withValues(alpha: 0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Debug: Detected Notes (Mock Mode)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                'Position: ${_currentPosition.measureIndex + 1}/${_score?.measureCount ?? 0} • Note ${_currentPosition.noteIndex + 1}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          latestNote.when(
            data: (note) => Text(
              'Latest: ${note.pitch} (${note.confidence.toStringAsFixed(2)})',
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            loading: () => const Text(
              'Listening...',
              style: TextStyle(color: Colors.white70),
            ),
            error: (err, stack) => Text(
              'Error: $err',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total notes detected: ${detectedNotes.length}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Get color for synchronization confidence indicator
  Color _getSyncColor(double confidence) {
    if (confidence >= 0.8) {
      return Colors.greenAccent;
    } else if (confidence >= 0.5) {
      return Colors.orangeAccent;
    } else {
      return Colors.redAccent;
    }
  }
}
