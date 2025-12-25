import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/audio_providers.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  bool _isScoreLoaded = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
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
      } else {
        await audioService.startRecording();
        ref.read(isRecordingProvider.notifier).state = true;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording error: $e')),
        );
      }
    }
  }

  void _loadScore() {
    setState(() {
      _isScoreLoaded = true;
    });
    // TODO: Load MusicXML file and render in WebView
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Score loaded successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = ref.watch(isRecordingProvider);
    final latestNote = ref.watch(latestNoteProvider);
    final detectedNotes = ref.watch(audioStreamNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Session'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
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
              child: _isScoreLoaded
                  ? Column(
                      children: [
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Score will be rendered here using WebView + OSMD',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        // Debug: Show detected notes
                        if (isRecording) _buildDebugNotesPanel(latestNote, detectedNotes),
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
                            'No score loaded',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadScore,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Load Score'),
                          ),
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

                      // Zoom Controls
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.zoom_in),
                            onPressed: () {
                              // TODO: Implement zoom in
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.zoom_out),
                            onPressed: () {
                              // TODO: Implement zoom out
                            },
                          ),
                        ],
                      ),

                      // Auto-scroll Toggle
                      IconButton.filled(
                        icon: const Icon(Icons.auto_awesome),
                        onPressed: () {
                          // TODO: Toggle auto-scroll
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Auto-scroll toggled')),
                          );
                        },
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
          const Text(
            'Debug: Detected Notes (Mock Mode)',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
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
}
