import 'package:flutter_sound/flutter_sound.dart';

class AudioConfig {
  final int sampleRate; // Hz
  final int channels; // Mono = 1, Stereo = 2
  final int bitsPerSample; // 16-bit PCM
  final Codec codec;
  final int bufferSize; // samples
  final Duration chunkDuration; // Duration of each audio chunk

  const AudioConfig({
    this.sampleRate = 44100,
    this.channels = 1,
    this.bitsPerSample = 16,
    this.codec = Codec.pcm16,
    this.bufferSize = 4096,
    this.chunkDuration = const Duration(milliseconds: 100),
  });

  int get bytesPerSecond => sampleRate * channels * (bitsPerSample ~/ 8);
  int get chunkSizeBytes =>
      (bytesPerSecond * chunkDuration.inMilliseconds / 1000).round();

  @override
  String toString() {
    return 'AudioConfig($sampleRate Hz, $channels ch, $bitsPerSample-bit, '
        '${chunkDuration.inMilliseconds}ms chunks)';
  }
}
