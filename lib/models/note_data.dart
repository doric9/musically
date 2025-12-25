class NoteData {
  final String pitch; // e.g., "C4", "D#5"
  final double frequency; // Hz
  final int timestamp; // ms
  final double confidence; // 0-1
  final int velocity; // 0-127 (MIDI velocity)

  NoteData({
    required this.pitch,
    required this.frequency,
    required this.timestamp,
    required this.confidence,
    required this.velocity,
  });

  factory NoteData.fromJson(Map<String, dynamic> json) {
    return NoteData(
      pitch: json['pitch'] as String,
      frequency: (json['frequency'] as num).toDouble(),
      timestamp: json['timestamp'] as int,
      confidence: (json['confidence'] as num).toDouble(),
      velocity: json['velocity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pitch': pitch,
      'frequency': frequency,
      'timestamp': timestamp,
      'confidence': confidence,
      'velocity': velocity,
    };
  }

  @override
  String toString() {
    return 'NoteData(pitch: $pitch, freq: ${frequency.toStringAsFixed(1)}Hz, '
        'confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}
