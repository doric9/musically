import 'dart:math';
import '../models/note_data.dart';
import '../models/score.dart';

/// Service that synchronizes detected notes with the musical score
/// Uses Dynamic Time Warping (DTW) algorithm for robust matching
class ScoreSyncService {
  final Score score;
  final Duration timingTolerance;
  final double pitchMatchThreshold;

  ScorePosition _currentPosition = ScorePosition.initial();
  final List<NoteData> _recentDetections = [];
  final int _maxRecentDetections = 10;

  ScoreSyncService({
    required this.score,
    this.timingTolerance = const Duration(milliseconds: 200),
    this.pitchMatchThreshold = 0.7,
  });

  /// Get current position in the score
  ScorePosition get currentPosition => _currentPosition;

  /// Process a newly detected note and update position
  ScorePosition processDetectedNote(NoteData detectedNote) {
    // Add to recent detections buffer
    _recentDetections.add(detectedNote);
    if (_recentDetections.length > _maxRecentDetections) {
      _recentDetections.removeAt(0);
    }

    // Find best match in score
    final match = _findBestMatch(detectedNote);
    if (match != null) {
      _currentPosition = match;
    }

    return _currentPosition;
  }

  /// Find the best matching position in the score for a detected note
  ScorePosition? _findBestMatch(NoteData detectedNote) {
    final currentMeasure = score.getMeasure(_currentPosition.measureIndex);
    if (currentMeasure == null) return null;

    // First, try to match within current measure
    final localMatch = _matchWithinMeasure(
      detectedNote,
      currentMeasure,
      _currentPosition.noteIndex,
    );
    if (localMatch != null) {
      return localMatch;
    }

    // Try next measure
    if (_currentPosition.measureIndex + 1 < score.measureCount) {
      final nextMeasure = score.getMeasure(_currentPosition.measureIndex + 1);
      if (nextMeasure != null) {
        final nextMeasureMatch = _matchWithinMeasure(
          detectedNote,
          nextMeasure,
          0,
        );
        if (nextMeasureMatch != null) {
          return nextMeasureMatch;
        }
      }
    }

    // Try previous measure (in case of backtracking)
    if (_currentPosition.measureIndex > 0) {
      final prevMeasure = score.getMeasure(_currentPosition.measureIndex - 1);
      if (prevMeasure != null) {
        final prevMeasureMatch = _matchWithinMeasure(
          detectedNote,
          prevMeasure,
          0,
        );
        if (prevMeasureMatch != null) {
          return prevMeasureMatch;
        }
      }
    }

    return null;
  }

  /// Try to match a detected note within a specific measure
  ScorePosition? _matchWithinMeasure(
    NoteData detectedNote,
    Measure measure,
    int startNoteIndex,
  ) {
    double bestScore = 0.0;
    int? bestNoteIndex;

    // Search forward from current position
    for (int i = startNoteIndex; i < measure.notes.length; i++) {
      final scoreNote = measure.notes[i];
      final matchScore = _calculateMatchScore(detectedNote, scoreNote);

      if (matchScore > bestScore && matchScore >= pitchMatchThreshold) {
        bestScore = matchScore;
        bestNoteIndex = i;
      }

      // Stop searching if we've gone too far ahead
      if (i > startNoteIndex + 5) break;
    }

    if (bestNoteIndex != null) {
      return ScorePosition.fromIndices(measure.index, bestNoteIndex, score);
    }

    return null;
  }

  /// Calculate match score between detected note and score note
  double _calculateMatchScore(NoteData detected, ScoreNote scoreNote) {
    double score = 0.0;

    // Pitch matching (most important)
    if (scoreNote.matchesPitch(detected.pitch)) {
      score += 0.7;
    } else if (_isOctaveEquivalent(detected.pitch, scoreNote.pitch)) {
      // Octave error is common, give partial credit
      score += 0.3;
    }

    // Confidence boost
    score += detected.confidence * 0.2;

    // Velocity similarity (if available)
    if (detected.velocity > 0) {
      final velocityDiff = (detected.velocity - 64).abs() / 127.0;
      score += (1.0 - velocityDiff) * 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Check if two pitches are octave equivalents
  bool _isOctaveEquivalent(String pitch1, String pitch2) {
    final note1 = pitch1.substring(0, pitch1.length - 1);
    final note2 = pitch2.substring(0, pitch2.length - 1);
    return note1 == note2;
  }

  /// Advanced synchronization using DTW on recent note sequence
  ScorePosition? synchronizeSequence() {
    if (_recentDetections.length < 3) {
      return null; // Need at least 3 notes for sequence matching
    }

    final currentMeasure = score.getMeasure(_currentPosition.measureIndex);
    if (currentMeasure == null) return null;

    // Get expected note sequence from current position
    final expectedNotes = _getExpectedNoteSequence(5);
    if (expectedNotes.isEmpty) return null;

    // Calculate DTW distance
    final dtw = _calculateDTW(_recentDetections, expectedNotes);
    final normalizedDistance = dtw / max(_recentDetections.length, expectedNotes.length);

    // If DTW distance is acceptable, we're synchronized
    if (normalizedDistance < 0.5) {
      return _currentPosition;
    }

    // Otherwise, try to find better alignment
    return _findBestAlignment();
  }

  /// Get expected note sequence from current position
  List<ScoreNote> _getExpectedNoteSequence(int count) {
    final notes = <ScoreNote>[];
    var pos = _currentPosition;

    while (notes.length < count && !pos.isAtEnd(score)) {
      final measure = score.getMeasure(pos.measureIndex);
      final note = measure?.getNote(pos.noteIndex);
      if (note != null) {
        notes.add(note);
      }
      pos = pos.advance(score);
    }

    return notes;
  }

  /// Calculate Dynamic Time Warping distance
  double _calculateDTW(List<NoteData> detected, List<ScoreNote> expected) {
    final n = detected.length;
    final m = expected.length;

    // Initialize DTW matrix
    final dtw = List.generate(
      n + 1,
      (_) => List.filled(m + 1, double.infinity),
    );
    dtw[0][0] = 0;

    // Fill DTW matrix
    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        final cost = _noteMismatchCost(detected[i - 1], expected[j - 1]);
        dtw[i][j] = cost + min(
          min(dtw[i - 1][j], dtw[i][j - 1]),
          dtw[i - 1][j - 1],
        );
      }
    }

    return dtw[n][m];
  }

  /// Calculate mismatch cost between detected and expected note
  double _noteMismatchCost(NoteData detected, ScoreNote expected) {
    if (expected.matchesPitch(detected.pitch)) {
      return 0.0; // Perfect match
    } else if (_isOctaveEquivalent(detected.pitch, expected.pitch)) {
      return 0.5; // Octave error
    } else {
      return 1.0; // Complete mismatch
    }
  }

  /// Find best alignment by searching nearby positions
  ScorePosition? _findBestAlignment() {
    double bestDistance = double.infinity;
    ScorePosition? bestPosition;

    // Search window: ±2 measures from current position
    final startMeasure = max(0, _currentPosition.measureIndex - 2);
    final endMeasure = min(
      score.measureCount - 1,
      _currentPosition.measureIndex + 2,
    );

    for (int measureIdx = startMeasure; measureIdx <= endMeasure; measureIdx++) {
      final measure = score.getMeasure(measureIdx);
      if (measure == null) continue;

      for (int noteIdx = 0; noteIdx < measure.notes.length; noteIdx++) {
        final testPosition = ScorePosition.fromIndices(
          measureIdx,
          noteIdx,
          score,
        );

        // Temporarily set position and calculate DTW
        final savedPosition = _currentPosition;
        _currentPosition = testPosition;
        final expectedNotes = _getExpectedNoteSequence(5);
        _currentPosition = savedPosition;

        if (expectedNotes.isEmpty) continue;

        final distance = _calculateDTW(_recentDetections, expectedNotes);
        if (distance < bestDistance) {
          bestDistance = distance;
          bestPosition = testPosition;
        }
      }
    }

    return bestPosition;
  }

  /// Reset synchronization to beginning
  void reset() {
    _currentPosition = ScorePosition.initial();
    _recentDetections.clear();
  }

  /// Manually set position (for user seeking)
  void setPosition(ScorePosition position) {
    _currentPosition = position;
    _recentDetections.clear();
  }

  /// Get expected next note(s) for look-ahead
  List<ScoreNote> getUpcomingNotes(int count) {
    final notes = <ScoreNote>[];
    var pos = _currentPosition.advance(score);

    while (notes.length < count && !pos.isAtEnd(score)) {
      final measure = score.getMeasure(pos.measureIndex);
      final note = measure?.getNote(pos.noteIndex);
      if (note != null) {
        notes.add(note);
      }
      pos = pos.advance(score);
    }

    return notes;
  }

  /// Calculate overall synchronization confidence
  double getSynchronizationConfidence() {
    if (_recentDetections.isEmpty) return 0.0;

    final expectedNotes = _getExpectedNoteSequence(_recentDetections.length);
    if (expectedNotes.isEmpty) return 0.0;

    final dtw = _calculateDTW(_recentDetections, expectedNotes);
    final maxPossibleDistance = _recentDetections.length.toDouble();
    final confidence = 1.0 - (dtw / maxPossibleDistance);

    return confidence.clamp(0.0, 1.0);
  }
}
