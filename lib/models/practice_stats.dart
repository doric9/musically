import 'note_data.dart';
import 'score.dart';

/// Statistics for a single practice session
class SessionStats {
  final String id;
  final String scoreId;
  final String scoreTitle;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;

  // Accuracy metrics
  final int totalNotesInScore;
  final int notesPlayed;
  final int correctNotes;
  final int incorrectNotes;
  final int missedNotes;

  // Timing metrics
  final int onTimeNotes; // Within ±100ms
  final int earlyNotes;
  final int lateNotes;
  final double averageTimingError; // in milliseconds

  // Progress tracking
  final int furthestMeasureReached;
  final bool completedScore;

  // Confidence
  final double averageConfidence;
  final double averageSyncConfidence;

  SessionStats({
    required this.id,
    required this.scoreId,
    required this.scoreTitle,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.totalNotesInScore,
    required this.notesPlayed,
    required this.correctNotes,
    required this.incorrectNotes,
    required this.missedNotes,
    required this.onTimeNotes,
    required this.earlyNotes,
    required this.lateNotes,
    required this.averageTimingError,
    required this.furthestMeasureReached,
    required this.completedScore,
    required this.averageConfidence,
    required this.averageSyncConfidence,
  });

  /// Calculate accuracy percentage (0-100)
  double get accuracy {
    if (notesPlayed == 0) return 0.0;
    return (correctNotes / notesPlayed * 100).clamp(0.0, 100.0);
  }

  /// Calculate timing accuracy percentage (0-100)
  double get timingAccuracy {
    if (notesPlayed == 0) return 0.0;
    return (onTimeNotes / notesPlayed * 100).clamp(0.0, 100.0);
  }

  /// Calculate overall score (weighted average)
  double get overallScore {
    final accuracyWeight = 0.5;
    final timingWeight = 0.3;
    final confidenceWeight = 0.2;

    return (accuracy * accuracyWeight +
            timingAccuracy * timingWeight +
            averageSyncConfidence * 100 * confidenceWeight)
        .clamp(0.0, 100.0);
  }

  /// Get performance grade (A, B, C, D, F)
  String get grade {
    final score = overallScore;
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  /// Get progress percentage through score
  double get progressPercentage {
    if (totalNotesInScore == 0) return 0.0;
    return (notesPlayed / totalNotesInScore * 100).clamp(0.0, 100.0);
  }

  factory SessionStats.initial({
    required String scoreId,
    required String scoreTitle,
    required int totalNotesInScore,
  }) {
    return SessionStats(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      scoreId: scoreId,
      scoreTitle: scoreTitle,
      startTime: DateTime.now(),
      duration: Duration.zero,
      totalNotesInScore: totalNotesInScore,
      notesPlayed: 0,
      correctNotes: 0,
      incorrectNotes: 0,
      missedNotes: 0,
      onTimeNotes: 0,
      earlyNotes: 0,
      lateNotes: 0,
      averageTimingError: 0.0,
      furthestMeasureReached: 0,
      completedScore: false,
      averageConfidence: 0.0,
      averageSyncConfidence: 0.0,
    );
  }

  SessionStats copyWith({
    String? id,
    String? scoreId,
    String? scoreTitle,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    int? totalNotesInScore,
    int? notesPlayed,
    int? correctNotes,
    int? incorrectNotes,
    int? missedNotes,
    int? onTimeNotes,
    int? earlyNotes,
    int? lateNotes,
    double? averageTimingError,
    int? furthestMeasureReached,
    bool? completedScore,
    double? averageConfidence,
    double? averageSyncConfidence,
  }) {
    return SessionStats(
      id: id ?? this.id,
      scoreId: scoreId ?? this.scoreId,
      scoreTitle: scoreTitle ?? this.scoreTitle,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      totalNotesInScore: totalNotesInScore ?? this.totalNotesInScore,
      notesPlayed: notesPlayed ?? this.notesPlayed,
      correctNotes: correctNotes ?? this.correctNotes,
      incorrectNotes: incorrectNotes ?? this.incorrectNotes,
      missedNotes: missedNotes ?? this.missedNotes,
      onTimeNotes: onTimeNotes ?? this.onTimeNotes,
      earlyNotes: earlyNotes ?? this.earlyNotes,
      lateNotes: lateNotes ?? this.lateNotes,
      averageTimingError: averageTimingError ?? this.averageTimingError,
      furthestMeasureReached:
          furthestMeasureReached ?? this.furthestMeasureReached,
      completedScore: completedScore ?? this.completedScore,
      averageConfidence: averageConfidence ?? this.averageConfidence,
      averageSyncConfidence:
          averageSyncConfidence ?? this.averageSyncConfidence,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scoreId': scoreId,
      'scoreTitle': scoreTitle,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration.inSeconds,
      'totalNotesInScore': totalNotesInScore,
      'notesPlayed': notesPlayed,
      'correctNotes': correctNotes,
      'incorrectNotes': incorrectNotes,
      'missedNotes': missedNotes,
      'onTimeNotes': onTimeNotes,
      'earlyNotes': earlyNotes,
      'lateNotes': lateNotes,
      'averageTimingError': averageTimingError,
      'furthestMeasureReached': furthestMeasureReached,
      'completedScore': completedScore,
      'averageConfidence': averageConfidence,
      'averageSyncConfidence': averageSyncConfidence,
    };
  }

  factory SessionStats.fromJson(Map<String, dynamic> json) {
    return SessionStats(
      id: json['id'] as String,
      scoreId: json['scoreId'] as String,
      scoreTitle: json['scoreTitle'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      duration: Duration(seconds: json['duration'] as int),
      totalNotesInScore: json['totalNotesInScore'] as int,
      notesPlayed: json['notesPlayed'] as int,
      correctNotes: json['correctNotes'] as int,
      incorrectNotes: json['incorrectNotes'] as int,
      missedNotes: json['missedNotes'] as int,
      onTimeNotes: json['onTimeNotes'] as int,
      earlyNotes: json['earlyNotes'] as int,
      lateNotes: json['lateNotes'] as int,
      averageTimingError: (json['averageTimingError'] as num).toDouble(),
      furthestMeasureReached: json['furthestMeasureReached'] as int,
      completedScore: json['completedScore'] as bool,
      averageConfidence: (json['averageConfidence'] as num).toDouble(),
      averageSyncConfidence: (json['averageSyncConfidence'] as num).toDouble(),
    );
  }
}

/// Detailed accuracy information for a single note
class NoteAccuracy {
  final ScoreNote expectedNote;
  final NoteData? playedNote;
  final int timestamp; // When it was supposed to be played
  final int? actualTimestamp; // When it was actually played
  final bool wasPlayed;
  final bool wasCorrect;
  final int? timingError; // in milliseconds (+ = late, - = early)

  NoteAccuracy({
    required this.expectedNote,
    this.playedNote,
    required this.timestamp,
    this.actualTimestamp,
    required this.wasPlayed,
    required this.wasCorrect,
    this.timingError,
  });

  /// Check if note was played on time (within ±100ms)
  bool get wasOnTime {
    if (timingError == null) return false;
    return timingError!.abs() <= 100;
  }

  /// Check if note was played early
  bool get wasEarly {
    if (timingError == null) return false;
    return timingError! < -100;
  }

  /// Check if note was played late
  bool get wasLate {
    if (timingError == null) return false;
    return timingError! > 100;
  }

  factory NoteAccuracy.missed(ScoreNote note, int timestamp) {
    return NoteAccuracy(
      expectedNote: note,
      timestamp: timestamp,
      wasPlayed: false,
      wasCorrect: false,
    );
  }

  factory NoteAccuracy.played({
    required ScoreNote expectedNote,
    required NoteData playedNote,
    required int expectedTimestamp,
    required int actualTimestamp,
  }) {
    final wasCorrect = expectedNote.matchesPitch(playedNote.pitch);
    final timingError = actualTimestamp - expectedTimestamp;

    return NoteAccuracy(
      expectedNote: expectedNote,
      playedNote: playedNote,
      timestamp: expectedTimestamp,
      actualTimestamp: actualTimestamp,
      wasPlayed: true,
      wasCorrect: wasCorrect,
      timingError: timingError,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expectedNote': expectedNote.toJson(),
      'playedNote': playedNote?.toJson(),
      'timestamp': timestamp,
      'actualTimestamp': actualTimestamp,
      'wasPlayed': wasPlayed,
      'wasCorrect': wasCorrect,
      'timingError': timingError,
    };
  }

  factory NoteAccuracy.fromJson(Map<String, dynamic> json) {
    return NoteAccuracy(
      expectedNote: ScoreNote.fromJson(json['expectedNote'] as Map<String, dynamic>),
      playedNote: json['playedNote'] != null
          ? NoteData.fromJson(json['playedNote'] as Map<String, dynamic>)
          : null,
      timestamp: json['timestamp'] as int,
      actualTimestamp: json['actualTimestamp'] as int?,
      wasPlayed: json['wasPlayed'] as bool,
      wasCorrect: json['wasCorrect'] as bool,
      timingError: json['timingError'] as int?,
    );
  }
}

/// Practice history entry
class PracticeHistory {
  final List<SessionStats> sessions;

  PracticeHistory({required this.sessions});

  /// Get sessions for a specific score
  List<SessionStats> getSessionsForScore(String scoreId) {
    return sessions.where((s) => s.scoreId == scoreId).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  /// Get recent sessions (last N)
  List<SessionStats> getRecentSessions(int count) {
    final sorted = List<SessionStats>.from(sessions)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return sorted.take(count).toList();
  }

  /// Calculate average accuracy across all sessions
  double get averageAccuracy {
    if (sessions.isEmpty) return 0.0;
    return sessions.map((s) => s.accuracy).reduce((a, b) => a + b) /
        sessions.length;
  }

  /// Calculate total practice time
  Duration get totalPracticeTime {
    return sessions.fold(
      Duration.zero,
      (total, session) => total + session.duration,
    );
  }

  /// Get improvement trend (comparing recent vs older sessions)
  double getImprovementTrend({int recentCount = 5, int olderCount = 5}) {
    if (sessions.length < recentCount + olderCount) return 0.0;

    final sorted = List<SessionStats>.from(sessions)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    final recent = sorted.take(recentCount).toList();
    final older = sorted.skip(recentCount).take(olderCount).toList();

    final recentAvg =
        recent.map((s) => s.overallScore).reduce((a, b) => a + b) /
            recentCount;
    final olderAvg =
        older.map((s) => s.overallScore).reduce((a, b) => a + b) / olderCount;

    return recentAvg - olderAvg;
  }

  Map<String, dynamic> toJson() {
    return {
      'sessions': sessions.map((s) => s.toJson()).toList(),
    };
  }

  factory PracticeHistory.fromJson(Map<String, dynamic> json) {
    return PracticeHistory(
      sessions: (json['sessions'] as List)
          .map((s) => SessionStats.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
