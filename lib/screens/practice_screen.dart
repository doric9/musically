import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  bool _isRecording = false;
  bool _isScoreLoaded = false;

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      // TODO: Start audio recording and Gemini API streaming
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording started...')),
      );
    } else {
      // TODO: Stop audio recording
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording stopped')),
      );
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
              child: Center(
                child: _isScoreLoaded
                    ? const Text(
                        'Score will be rendered here using WebView + OSMD',
                        style: TextStyle(color: Colors.grey),
                      )
                    : Column(
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
                  if (_isRecording)
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

                  // Main Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Record/Stop Button
                      FloatingActionButton.large(
                        onPressed: _toggleRecording,
                        backgroundColor:
                            _isRecording ? Colors.red : Colors.blue,
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
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
}
