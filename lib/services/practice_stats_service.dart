import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/practice_stats.dart';
import '../models/note_data.dart';
import '../models/score.dart';

/// Service for tracking practice session statistics
class PracticeStatsService extends ChangeNotifier {
  final Score score;

  SessionStats _currentSession;
  final List<NoteAccuracy> _noteAccuracies = [];
  final List<double> _syncConfidences = [];
  final List<double> _noteConfidences = [];

  DateTime? _sessionStartTime;
  Timer? _durationTimer;

  PracticeStatsService({required this.score})
      : _currentSession = SessionStats.initial(
          scoreId: score.id,
          scoreTitle: score.title,
          totalNotesInScore: score.noteCount,
        );

  /// Get current session statistics
  SessionStats get currentSession => _currentSession;

  /// Get all note accuracies
  List<NoteAccuracy> get noteAccuracies => List.unmodifiable(_noteAccuracies);

  /// Check if session is active
  bool get isActive => _sessionStartTime != null;

  /// Start tracking a new session
  void startSession() {
    _sessionStartTime = DateTime.now();
    _currentSession = SessionStats.initial(
      scoreId: score.id,
      scoreTitle: score.title,
      totalNotesInScore: score.noteCount,
    );
    _noteAccuracies.clear();
    _syncConfidences.clear();
    _noteConfidences.clear();

    // Update duration every second
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateDuration();
    });

    notifyListeners();
  }

  /// Stop the current session
  void endSession() {
    _durationTimer?.cancel();
    _durationTimer = null;

    if (_sessionStartTime != null) {
      _currentSession = _currentSession.copyWith(
        endTime: DateTime.now(),
        duration: DateTime.now().difference(_sessionStartTime!),
        completedScore: _hasCompletedScore(),
        averageConfidence: _calculateAverageConfidence(),
        averageSyncConfidence: _calculateAverageSyncConfidence(),
        averageTimingError: _calculateAverageTimingError(),
      );
      _sessionStartTime = null;
      notifyListeners();
    }
  }

  /// Record a played note and compare with expected note
  void recordPlayedNote({
    required ScoreNote expectedNote,
    required NoteData playedNote,
    required ScorePosition position,
    required double syncConfidence,
  }) {
    if (!isActive) return;

    final expectedTimestamp = _calculateExpectedTimestamp(position);
    final actualTimestamp = DateTime.now().millisecondsSinceEpoch;

    final accuracy = NoteAccuracy.played(
      expectedNote: expectedNote,
      playedNote: playedNote,
      expectedTimestamp: expectedTimestamp,
      actualTimestamp: actualTimestamp,
    );

    _noteAccuracies.add(accuracy);
    _syncConfidences.add(syncConfidence);
    _noteConfidences.add(playedNote.confidence);

    // Update statistics
    _currentSession = _currentSession.copyWith(
      notesPlayed: _currentSession.notesPlayed + 1,
      correctNotes: accuracy.wasCorrect
          ? _currentSession.correctNotes + 1
          : _currentSession.correctNotes,
      incorrectNotes: !accuracy.wasCorrect
          ? _currentSession.incorrectNotes + 1
          : _currentSession.incorrectNotes,
      onTimeNotes: accuracy.wasOnTime
          ? _currentSession.onTimeNotes + 1
          : _currentSession.onTimeNotes,
      earlyNotes: accuracy.wasEarly
          ? _currentSession.earlyNotes + 1
          : _currentSession.earlyNotes,
      lateNotes: accuracy.wasLate
          ? _currentSession.lateNotes + 1
          : _currentSession.lateNotes,
      furthestMeasureReached: position.measureIndex >
              _currentSession.furthestMeasureReached
          ? position.measureIndex
          : _currentSession.furthestMeasureReached,
    );

    notifyListeners();
  }

  /// Record a missed note (not played when expected)
  void recordMissedNote({
    required ScoreNote expectedNote,
    required ScorePosition position,
  }) {
    if (!isActive) return;

    final expectedTimestamp = _calculateExpectedTimestamp(position);
    final accuracy = NoteAccuracy.missed(expectedNote, expectedTimestamp);

    _noteAccuracies.add(accuracy);

    _currentSession = _currentSession.copyWith(
      missedNotes: _currentSession.missedNotes + 1,
    );

    notifyListeners();
  }

  /// Update session duration
  void _updateDuration() {
    if (_sessionStartTime != null) {
      _currentSession = _currentSession.copyWith(
        duration: DateTime.now().difference(_sessionStartTime!),
      );
      notifyListeners();
    }
  }

  /// Calculate expected timestamp for a position in the score
  int _calculateExpectedTimestamp(ScorePosition position) {
    if (_sessionStartTime == null) {
      return DateTime.now().millisecondsSinceEpoch;
    }

    // Use the position's timestamp relative to score start
    return _sessionStartTime!.millisecondsSinceEpoch + position.timestamp;
  }

  /// Calculate average note confidence
  double _calculateAverageConfidence() {
    if (_noteConfidences.isEmpty) return 0.0;
    return _noteConfidences.reduce((a, b) => a + b) / _noteConfidences.length;
  }

  /// Calculate average sync confidence
  double _calculateAverageSyncConfidence() {
    if (_syncConfidences.isEmpty) return 0.0;
    return _syncConfidences.reduce((a, b) => a + b) / _syncConfidences.length;
  }

  /// Calculate average timing error
  double _calculateAverageTimingError() {
    final timingErrors = _noteAccuracies
        .where((a) => a.timingError != null)
        .map((a) => a.timingError!.abs())
        .toList();

    if (timingErrors.isEmpty) return 0.0;
    return timingErrors.reduce((a, b) => a + b) / timingErrors.length;
  }

  /// Check if the user has completed the entire score
  bool _hasCompletedScore() {
    return _currentSession.furthestMeasureReached >= score.measureCount - 1;
  }

  /// Get real-time accuracy metrics
  Map<String, double> getRealtimeMetrics() {
    return {
      'accuracy': _currentSession.accuracy,
      'timingAccuracy': _currentSession.timingAccuracy,
      'overallScore': _currentSession.overallScore,
      'progress': _currentSession.progressPercentage,
    };
  }

  /// Get note accuracy for specific measure
  List<NoteAccuracy> getAccuraciesForMeasure(int measureIndex) {
    return _noteAccuracies.where((accuracy) {
      final measure = score.getMeasure(measureIndex);
      if (measure == null) return false;
      return measure.notes.contains(accuracy.expectedNote);
    }).toList();
  }

  /// Get timing distribution (early, on-time, late percentages)
  Map<String, double> getTimingDistribution() {
    final total = _currentSession.notesPlayed;
    if (total == 0) {
      return {'early': 0.0, 'onTime': 0.0, 'late': 0.0};
    }

    return {
      'early': (_currentSession.earlyNotes / total * 100),
      'onTime': (_currentSession.onTimeNotes / total * 100),
      'late': (_currentSession.lateNotes / total * 100),
    };
  }

  /// Reset the current session
  void reset() {
    endSession();
    _noteAccuracies.clear();
    _syncConfidences.clear();
    _noteConfidences.clear();
    _currentSession = SessionStats.initial(
      scoreId: score.id,
      scoreTitle: score.title,
      totalNotesInScore: score.noteCount,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }
}
