import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/note_data.dart';

class GeminiAudioService {
  WebSocketChannel? _channel;
  final String apiKey;
  final String websocketUrl;

  final StreamController<NoteData> _noteStreamController =
      StreamController<NoteData>.broadcast();
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  final StreamController<double> _confidenceController =
      StreamController<double>.broadcast();

  bool _isConnected = false;
  final List<double> _recentConfidenceScores = [];

  GeminiAudioService({
    required this.apiKey,
    this.websocketUrl = 'wss://your-backend.com/audio',
  });

  Stream<NoteData> get noteStream => _noteStreamController.stream;
  Stream<String> get statusStream => _statusController.stream;
  Stream<double> get confidenceStream => _confidenceController.stream;
  bool get isConnected => _isConnected;

  /// Connect to Gemini Live API via WebSocket
  Future<void> connectLiveAPI() async {
    if (_isConnected) {
      _updateStatus('Already connected');
      return;
    }

    try {
      // TODO: Replace with actual backend WebSocket URL
      // For now, this is a placeholder for development
      _updateStatus('Connecting to Gemini API...');

      // In production, connect to your backend WebSocket endpoint
      // _channel = WebSocketChannel.connect(Uri.parse(websocketUrl));

      // For development, simulate connection
      _isConnected = true;
      _updateStatus('Connected to Gemini API (mock mode)');

      // Listen to WebSocket messages
      // _channel?.stream.listen(
      //   _handleResponse,
      //   onError: _handleError,
      //   onDone: _handleDisconnect,
      // );
    } catch (e) {
      _updateStatus('Failed to connect: $e');
      _isConnected = false;
      rethrow;
    }
  }

  /// Stream audio chunks to Gemini API
  void streamAudioChunk(Uint8List audioData) {
    if (!_isConnected) {
      _updateStatus('Not connected to Gemini API');
      return;
    }

    try {
      // TODO: Send audio data to backend via WebSocket
      // _channel?.sink.add(audioData);

      // For development, simulate note detection
      _simulateNoteDetection();
    } catch (e) {
      _updateStatus('Failed to stream audio: $e');
    }
  }

  /// Handle WebSocket responses from Gemini API
  // ignore: unused_element
  void _handleResponse(dynamic response) {
    try {
      final data = jsonDecode(response as String) as Map<String, dynamic>;

      if (data.containsKey('notes')) {
        final notes = data['notes'] as List<dynamic>;
        for (final noteJson in notes) {
          final note = NoteData.fromJson(noteJson as Map<String, dynamic>);
          _noteStreamController.add(note);
          _updateConfidence(note.confidence);
        }
      }

      if (data.containsKey('status')) {
        _updateStatus(data['status'] as String);
      }
    } catch (e) {
      _updateStatus('Error parsing response: $e');
    }
  }

  /// Handle WebSocket errors
  // ignore: unused_element
  void _handleError(Object error) {
    _updateStatus('WebSocket error: $error');
    _isConnected = false;
  }

  /// Handle WebSocket disconnect
  // ignore: unused_element
  void _handleDisconnect() {
    _updateStatus('Disconnected from Gemini API');
    _isConnected = false;
  }

  /// Disconnect from Gemini API
  Future<void> disconnect() async {
    if (!_isConnected) return;

    try {
      await _channel?.sink.close();
      _isConnected = false;
      _updateStatus('Disconnected');
    } catch (e) {
      _updateStatus('Error during disconnect: $e');
    }
  }

  /// Get average confidence score
  double getAverageConfidence() {
    if (_recentConfidenceScores.isEmpty) return 0.0;

    final sum =
        _recentConfidenceScores.reduce((value, element) => value + element);
    return sum / _recentConfidenceScores.length;
  }

  /// Update confidence score history
  void _updateConfidence(double confidence) {
    _recentConfidenceScores.add(confidence);

    // Keep only the last 50 scores
    if (_recentConfidenceScores.length > 50) {
      _recentConfidenceScores.removeAt(0);
    }

    _confidenceController.add(getAverageConfidence());
  }

  /// Simulate note detection for development/testing
  void _simulateNoteDetection() {
    // This is a mock implementation for development
    // In production, this would be replaced with actual Gemini API responses

    final random = DateTime.now().millisecondsSinceEpoch % 12;
    final notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final octaves = [3, 4, 5];

    final note = NoteData(
      pitch: '${notes[random]}${octaves[random % 3]}',
      frequency: 440.0 * (1 + random / 12),
      timestamp: DateTime.now().millisecondsSinceEpoch,
      confidence: 0.7 + (random / 40),
      velocity: 60 + random * 5,
    );

    _noteStreamController.add(note);
    _updateConfidence(note.confidence);
  }

  /// Dispose and clean up resources
  Future<void> dispose() async {
    await disconnect();
    await _noteStreamController.close();
    await _statusController.close();
    await _confidenceController.close();
  }

  void _updateStatus(String status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
}
