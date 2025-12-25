import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/audio_config.dart';
import '../models/note_data.dart';
import '../services/audio_input_service.dart';
import '../services/gemini_audio_service.dart';

// Audio Configuration Provider
final audioConfigProvider = Provider<AudioConfig>((ref) {
  return const AudioConfig(
    sampleRate: 44100,
    channels: 1,
    bitsPerSample: 16,
    chunkDuration: Duration(milliseconds: 100),
  );
});

// Audio Input Service Provider
final audioInputServiceProvider = Provider<AudioInputService>((ref) {
  final config = ref.watch(audioConfigProvider);
  final service = AudioInputService(config: config);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

// Gemini Audio Service Provider
final geminiAudioServiceProvider = Provider<GeminiAudioService>((ref) {
  const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'mock-api-key');
  final service = GeminiAudioService(apiKey: apiKey);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

// Recording State Provider
final isRecordingProvider = StateProvider<bool>((ref) => false);

// Detected Notes Stream Provider
final detectedNotesStreamProvider = StreamProvider<NoteData>((ref) {
  final geminiService = ref.watch(geminiAudioServiceProvider);
  return geminiService.noteStream;
});

// Latest Detected Note Provider
final latestNoteProvider = Provider<AsyncValue<NoteData>>((ref) {
  return ref.watch(detectedNotesStreamProvider);
});

// Audio Status Stream Provider
final audioStatusStreamProvider = StreamProvider<String>((ref) {
  final audioService = ref.watch(audioInputServiceProvider);
  return audioService.statusStream;
});

// Gemini Status Stream Provider
final geminiStatusStreamProvider = StreamProvider<String>((ref) {
  final geminiService = ref.watch(geminiAudioServiceProvider);
  return geminiService.statusStream;
});

// Average Confidence Score Provider
final averageConfidenceProvider = Provider<double>((ref) {
  final geminiService = ref.watch(geminiAudioServiceProvider);
  return geminiService.getAverageConfidence();
});

// Audio Stream Handler
class AudioStreamNotifier extends StateNotifier<List<NoteData>> {
  final AudioInputService audioService;
  final GeminiAudioService geminiService;

  AudioStreamNotifier(this.audioService, this.geminiService) : super([]) {
    _initialize();
  }

  void _initialize() {
    // Listen to audio stream and forward to Gemini
    audioService.audioStream.listen((audioData) {
      geminiService.streamAudioChunk(audioData);
    });

    // Listen to detected notes
    geminiService.noteStream.listen((note) {
      state = [...state, note];

      // Keep only the last 100 notes
      if (state.length > 100) {
        state = state.sublist(state.length - 100);
      }
    });
  }

  void clearNotes() {
    state = [];
  }
}

final audioStreamNotifierProvider =
    StateNotifierProvider<AudioStreamNotifier, List<NoteData>>((ref) {
  final audioService = ref.watch(audioInputServiceProvider);
  final geminiService = ref.watch(geminiAudioServiceProvider);

  return AudioStreamNotifier(audioService, geminiService);
});

// Permission State Provider
final microphonePermissionProvider = FutureProvider<bool>((ref) async {
  final audioService = ref.watch(audioInputServiceProvider);
  return await audioService.requestPermissions();
});
