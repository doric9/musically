import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:audio_session/audio_session.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/audio_config.dart';

class AudioInputService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final AudioConfig config;

  final StreamController<Uint8List> _audioStreamController =
      StreamController<Uint8List>.broadcast();
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();

  bool _isInitialized = false;
  bool _isRecording = false;

  AudioInputService({this.config = const AudioConfig()});

  Stream<Uint8List> get audioStream => _audioStreamController.stream;
  Stream<String> get statusStream => _statusController.stream;
  bool get isRecording => _isRecording;
  bool get isInitialized => _isInitialized;

  /// Request microphone permission
  Future<bool> requestPermissions() async {
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      _updateStatus('Microphone permission granted');
      return true;
    } else if (status.isDenied) {
      _updateStatus('Microphone permission denied');
      return false;
    } else if (status.isPermanentlyDenied) {
      _updateStatus('Microphone permission permanently denied');
      await openAppSettings();
      return false;
    }

    return false;
  }

  /// Initialize the audio recorder
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Open the recorder
      await _recorder.openRecorder();

      // Configure audio session
      final session = await AudioSession.instance;
      await session.configure(
        AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.allowBluetooth |
                  AVAudioSessionCategoryOptions.defaultToSpeaker,
          avAudioSessionMode: AVAudioSessionMode.measurement,
          avAudioSessionRouteSharingPolicy:
              AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
          androidAudioAttributes: const AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            flags: AndroidAudioFlags.none,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: true,
        ),
      );

      _isInitialized = true;
      _updateStatus('Audio recorder initialized');
    } catch (e) {
      _updateStatus('Failed to initialize recorder: $e');
      rethrow;
    }
  }

  /// Start recording audio
  Future<void> startRecording() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isRecording) {
      _updateStatus('Already recording');
      return;
    }

    try {
      await _recorder.startRecorder(
        toStream: _audioStreamController.sink,
        codec: config.codec,
        numChannels: config.channels,
        sampleRate: config.sampleRate,
        bitRate: config.sampleRate * config.bitsPerSample * config.channels,
      );

      _isRecording = true;
      _updateStatus('Recording started');
    } catch (e) {
      _updateStatus('Failed to start recording: $e');
      rethrow;
    }
  }

  /// Stop recording audio
  Future<void> stopRecording() async {
    if (!_isRecording) {
      _updateStatus('Not currently recording');
      return;
    }

    try {
      await _recorder.stopRecorder();
      _isRecording = false;
      _updateStatus('Recording stopped');
    } catch (e) {
      _updateStatus('Failed to stop recording: $e');
      rethrow;
    }
  }

  /// Toggle recording state
  Future<void> toggleRecording() async {
    if (_isRecording) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  /// Get current decibel level
  Stream<double>? getDecibelStream() {
    return _recorder.onProgress?.map((event) => event.decibels ?? 0.0);
  }

  /// Dispose and clean up resources
  Future<void> dispose() async {
    if (_isRecording) {
      await stopRecording();
    }

    if (_isInitialized) {
      await _recorder.closeRecorder();
      _isInitialized = false;
    }

    await _audioStreamController.close();
    await _statusController.close();
  }

  void _updateStatus(String status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
}
