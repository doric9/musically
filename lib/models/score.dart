/// Score data models for music sheet representation and synchronization
class Score {
  final String id;
  final String title;
  final String composer;
  final String musicXmlContent;
  final List<Measure> measures;
  final int totalDuration; // in milliseconds
  final String? description;
  final String? difficulty;

  const Score({
    required this.id,
    required this.title,
    required this.composer,
    required this.musicXmlContent,
    required this.measures,
    required this.totalDuration,
    this.description,
    this.difficulty,
  });

  int get measureCount => measures.length;
  int get noteCount => measures.fold(0, (sum, m) => sum + m.notes.length);

  /// Find measure by index
  Measure? getMeasure(int index) {
    if (index < 0 || index >= measures.length) return null;
    return measures[index];
  }

  /// Find measure containing a specific timestamp
  Measure? getMeasureAtTime(int timestamp) {
    for (final measure in measures) {
      if (timestamp >= measure.startTime &&
          timestamp < measure.startTime + measure.duration) {
        return measure;
      }
    }
    return null;
  }

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      id: json['id'] as String,
      title: json['title'] as String,
      composer: json['composer'] as String,
      musicXmlContent: json['musicXmlContent'] as String,
      measures: (json['measures'] as List)
          .map((m) => Measure.fromJson(m as Map<String, dynamic>))
          .toList(),
      totalDuration: json['totalDuration'] as int,
      description: json['description'] as String?,
      difficulty: json['difficulty'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'composer': composer,
      'musicXmlContent': musicXmlContent,
      'measures': measures.map((m) => m.toJson()).toList(),
      'totalDuration': totalDuration,
      'description': description,
      'difficulty': difficulty,
    };
  }
}

/// Represents a single measure in the score
class Measure {
  final int index;
  final int startTime; // milliseconds from start of piece
  final int duration; // milliseconds
  final List<ScoreNote> notes;
  final String timeSignature; // e.g., "4/4"
  final String? keySignature; // e.g., "C major"
  final int? tempo; // BPM

  const Measure({
    required this.index,
    required this.startTime,
    required this.duration,
    required this.notes,
    required this.timeSignature,
    this.keySignature,
    this.tempo,
  });

  /// Find note by index within this measure
  ScoreNote? getNote(int noteIndex) {
    if (noteIndex < 0 || noteIndex >= notes.length) return null;
    return notes[noteIndex];
  }

  /// Find note at specific timestamp within this measure
  ScoreNote? getNoteAtTime(int timestamp) {
    for (final note in notes) {
      if (timestamp >= note.startTime &&
          timestamp < note.startTime + note.duration) {
        return note;
      }
    }
    return null;
  }

  factory Measure.fromJson(Map<String, dynamic> json) {
    return Measure(
      index: json['index'] as int,
      startTime: json['startTime'] as int,
      duration: json['duration'] as int,
      notes: (json['notes'] as List)
          .map((n) => ScoreNote.fromJson(n as Map<String, dynamic>))
          .toList(),
      timeSignature: json['timeSignature'] as String,
      keySignature: json['keySignature'] as String?,
      tempo: json['tempo'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'startTime': startTime,
      'duration': duration,
      'notes': notes.map((n) => n.toJson()).toList(),
      'timeSignature': timeSignature,
      'keySignature': keySignature,
      'tempo': tempo,
    };
  }
}

/// Represents a single note in the score (renamed to avoid conflicts)
class ScoreNote {
  final String pitch; // e.g., "C4", "D#5"
  final int midiNumber; // MIDI note number (0-127)
  final int startTime; // milliseconds from measure start
  final int duration; // milliseconds
  final String noteType; // e.g., "quarter", "half", "whole", "eighth"
  final bool isDotted;
  final int? voice; // for multi-voice pieces
  final String? articulation; // e.g., "staccato", "legato"

  const ScoreNote({
    required this.pitch,
    required this.midiNumber,
    required this.startTime,
    required this.duration,
    required this.noteType,
    this.isDotted = false,
    this.voice,
    this.articulation,
  });

  /// Get octave number from pitch (e.g., "C4" -> 4)
  int get octave => int.parse(pitch.substring(pitch.length - 1));

  /// Get note name without octave (e.g., "C4" -> "C")
  String get noteName => pitch.substring(0, pitch.length - 1);

  /// Check if this note matches a detected pitch (with enharmonic equivalence)
  bool matchesPitch(String detectedPitch) {
    // Direct match
    if (pitch == detectedPitch) return true;

    // Check enharmonic equivalents (e.g., C# = Db)
    return _getEnharmonicEquivalents(pitch).contains(detectedPitch);
  }

  /// Get enharmonic equivalent pitches
  static List<String> _getEnharmonicEquivalents(String pitch) {
    final enharmonicMap = {
      'C#': 'Db',
      'Db': 'C#',
      'D#': 'Eb',
      'Eb': 'D#',
      'F#': 'Gb',
      'Gb': 'F#',
      'G#': 'Ab',
      'Ab': 'G#',
      'A#': 'Bb',
      'Bb': 'A#',
    };

    final octave = pitch.substring(pitch.length - 1);
    final noteName = pitch.substring(0, pitch.length - 1);

    final equivalent = enharmonicMap[noteName];
    return equivalent != null ? ['$equivalent$octave'] : [];
  }

  factory ScoreNote.fromJson(Map<String, dynamic> json) {
    return ScoreNote(
      pitch: json['pitch'] as String,
      midiNumber: json['midiNumber'] as int,
      startTime: json['startTime'] as int,
      duration: json['duration'] as int,
      noteType: json['noteType'] as String,
      isDotted: json['isDotted'] as bool? ?? false,
      voice: json['voice'] as int?,
      articulation: json['articulation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pitch': pitch,
      'midiNumber': midiNumber,
      'startTime': startTime,
      'duration': duration,
      'noteType': noteType,
      'isDotted': isDotted,
      'voice': voice,
      'articulation': articulation,
    };
  }
}

/// Represents the current position in the score during playback/practice
class ScorePosition {
  final int measureIndex;
  final int noteIndex;
  final int timestamp; // milliseconds from start
  final double progress; // 0.0 to 1.0 overall progress

  const ScorePosition({
    required this.measureIndex,
    required this.noteIndex,
    required this.timestamp,
    required this.progress,
  });

  /// Create position at the beginning of the score
  factory ScorePosition.initial() {
    return const ScorePosition(
      measureIndex: 0,
      noteIndex: 0,
      timestamp: 0,
      progress: 0.0,
    );
  }

  /// Create position from measure and note indices
  factory ScorePosition.fromIndices(
    int measureIndex,
    int noteIndex,
    Score score,
  ) {
    final measure = score.getMeasure(measureIndex);
    if (measure == null) {
      return ScorePosition.initial();
    }

    final note = measure.getNote(noteIndex);
    final timestamp = measure.startTime + (note?.startTime ?? 0);
    final progress = score.totalDuration > 0
        ? timestamp / score.totalDuration
        : 0.0;

    return ScorePosition(
      measureIndex: measureIndex,
      noteIndex: noteIndex,
      timestamp: timestamp,
      progress: progress.clamp(0.0, 1.0),
    );
  }

  /// Advance to next note
  ScorePosition advance(Score score) {
    final currentMeasure = score.getMeasure(measureIndex);
    if (currentMeasure == null) return this;

    // Try to advance within current measure
    if (noteIndex + 1 < currentMeasure.notes.length) {
      return ScorePosition.fromIndices(measureIndex, noteIndex + 1, score);
    }

    // Advance to next measure
    if (measureIndex + 1 < score.measureCount) {
      return ScorePosition.fromIndices(measureIndex + 1, 0, score);
    }

    // Already at the end
    return this;
  }

  /// Move to previous note
  ScorePosition rewind(Score score) {
    // Try to move back within current measure
    if (noteIndex > 0) {
      return ScorePosition.fromIndices(measureIndex, noteIndex - 1, score);
    }

    // Move to previous measure
    if (measureIndex > 0) {
      final previousMeasure = score.getMeasure(measureIndex - 1);
      if (previousMeasure != null && previousMeasure.notes.isNotEmpty) {
        return ScorePosition.fromIndices(
          measureIndex - 1,
          previousMeasure.notes.length - 1,
          score,
        );
      }
    }

    // Already at the beginning
    return this;
  }

  /// Check if this is the last note in the score
  bool isAtEnd(Score score) {
    return measureIndex >= score.measureCount - 1 &&
        noteIndex >= (score.getMeasure(measureIndex)?.notes.length ?? 0) - 1;
  }

  /// Check if this is the first note in the score
  bool isAtStart() {
    return measureIndex == 0 && noteIndex == 0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScorePosition &&
        other.measureIndex == measureIndex &&
        other.noteIndex == noteIndex;
  }

  @override
  int get hashCode => Object.hash(measureIndex, noteIndex);

  @override
  String toString() {
    return 'ScorePosition(measure: $measureIndex, note: $noteIndex, time: ${timestamp}ms, progress: ${(progress * 100).toStringAsFixed(1)}%)';
  }

  factory ScorePosition.fromJson(Map<String, dynamic> json) {
    return ScorePosition(
      measureIndex: json['measureIndex'] as int,
      noteIndex: json['noteIndex'] as int,
      timestamp: json['timestamp'] as int,
      progress: (json['progress'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'measureIndex': measureIndex,
      'noteIndex': noteIndex,
      'timestamp': timestamp,
      'progress': progress,
    };
  }
}
