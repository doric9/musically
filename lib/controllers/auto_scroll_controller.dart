import 'dart:async';
import 'package:flutter/material.dart';
import '../models/score.dart';
import '../widgets/score_viewer.dart';

/// Controller for automatic score scrolling with look-ahead
/// Provides smooth, predictive scrolling as the user plays
class AutoScrollController extends ChangeNotifier {
  final Score score;
  final GlobalKey<State<ScoreViewer>> scoreViewerKey;

  ScorePosition _currentPosition = ScorePosition.initial();
  bool _isEnabled = true;
  int _lookAheadMeasures = 2; // Show 2 measures ahead
  Timer? _scrollTimer;
  int? _targetMeasure;

  AutoScrollController({
    required this.score,
    required this.scoreViewerKey,
    int lookAheadMeasures = 2,
  }) : _lookAheadMeasures = lookAheadMeasures;

  /// Get current position
  ScorePosition get currentPosition => _currentPosition;

  /// Check if auto-scroll is enabled
  bool get isEnabled => _isEnabled;

  /// Get look-ahead measures count
  int get lookAheadMeasures => _lookAheadMeasures;

  /// Enable or disable auto-scroll
  void setEnabled(bool enabled) {
    if (_isEnabled == enabled) return;
    _isEnabled = enabled;
    notifyListeners();

    if (!enabled) {
      _cancelScheduledScroll();
    }
  }

  /// Set look-ahead distance in measures
  void setLookAhead(int measures) {
    if (_lookAheadMeasures == measures) return;
    _lookAheadMeasures = measures.clamp(1, 5);
    notifyListeners();
  }

  /// Update current position and trigger scroll if needed
  void updatePosition(ScorePosition newPosition) {
    if (_currentPosition == newPosition) return;

    final oldMeasure = _currentPosition.measureIndex;
    _currentPosition = newPosition;
    notifyListeners();

    // Trigger scroll if we've moved to a new measure
    if (_isEnabled && newPosition.measureIndex != oldMeasure) {
      _scheduleScroll();
    }
  }

  /// Schedule a smooth scroll to the current position
  void _scheduleScroll() {
    // Cancel any pending scroll
    _cancelScheduledScroll();

    // Calculate target measure (with look-ahead)
    final targetMeasure = _calculateTargetMeasure();
    if (targetMeasure == _targetMeasure) {
      return; // Already scrolling to this measure
    }

    _targetMeasure = targetMeasure;

    // Scroll immediately (smooth scroll is handled by the WebView)
    _performScroll(targetMeasure);
  }

  /// Calculate which measure should be at the top of the screen
  int _calculateTargetMeasure() {
    // Show current measure plus look-ahead, but keep current measure visible
    final targetMeasure = (_currentPosition.measureIndex - 1).clamp(
      0,
      score.measureCount - 1,
    );
    return targetMeasure;
  }

  /// Perform the actual scroll
  void _performScroll(int measureIndex) {
    final viewerState = scoreViewerKey.currentState;
    if (viewerState == null) return;

    // Get ScoreViewer widget
    final viewer = viewerState.widget as ScoreViewer;

    // Access the scroll method via reflection/callback
    // Note: This is a simplified version. In production, we'd expose
    // the scrollToMeasure method through a controller or callback
    _scrollToMeasure(measureIndex);
  }

  /// Scroll to specific measure (to be implemented via ScoreViewer)
  void _scrollToMeasure(int measureIndex) {
    // This will be called through the ScoreViewer's public API
    // For now, we'll emit an event that the widget can listen to
    notifyListeners();
  }

  /// Cancel any scheduled scroll
  void _cancelScheduledScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
  }

  /// Manually scroll to a specific measure
  void scrollToMeasure(int measureIndex, {bool updatePosition = true}) {
    if (measureIndex < 0 || measureIndex >= score.measureCount) return;

    if (updatePosition) {
      final newPosition = ScorePosition.fromIndices(measureIndex, 0, score);
      _currentPosition = newPosition;
      notifyListeners();
    }

    _targetMeasure = measureIndex;
    _performScroll(measureIndex);
  }

  /// Scroll forward by one page (based on screen size)
  void pageForward() {
    final nextMeasure = (_currentPosition.measureIndex + _lookAheadMeasures * 2)
        .clamp(0, score.measureCount - 1);
    scrollToMeasure(nextMeasure);
  }

  /// Scroll backward by one page
  void pageBackward() {
    final prevMeasure = (_currentPosition.measureIndex - _lookAheadMeasures * 2)
        .clamp(0, score.measureCount - 1);
    scrollToMeasure(prevMeasure);
  }

  /// Reset to beginning of score
  void reset() {
    _currentPosition = ScorePosition.initial();
    _targetMeasure = null;
    _cancelScheduledScroll();
    scrollToMeasure(0, updatePosition: false);
    notifyListeners();
  }

  /// Get scroll progress (0.0 to 1.0)
  double getScrollProgress() {
    if (score.measureCount <= 1) return 1.0;
    return _currentPosition.measureIndex / (score.measureCount - 1);
  }

  /// Check if we're near the end of the score
  bool isNearEnd() {
    return _currentPosition.measureIndex >= score.measureCount - 3;
  }

  /// Check if we're at the beginning of the score
  bool isAtStart() {
    return _currentPosition.measureIndex == 0;
  }

  @override
  void dispose() {
    _cancelScheduledScroll();
    super.dispose();
  }
}

/// Alternative implementation using AnimationController for smoother scrolling
class AnimatedAutoScrollController extends AutoScrollController {
  late AnimationController _animationController;
  Animation<double>? _scrollAnimation;

  AnimatedAutoScrollController({
    required super.score,
    required super.scoreViewerKey,
    required TickerProvider vsync,
    super.lookAheadMeasures,
  }) {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: vsync,
    );
  }

  /// Perform animated scroll
  @override
  void _performScroll(int measureIndex) {
    // Cancel any ongoing animation
    _animationController.stop();

    // Create tween from current to target measure
    final currentMeasure = _targetMeasure ?? _currentPosition.measureIndex;
    _scrollAnimation = Tween<double>(
      begin: currentMeasure.toDouble(),
      end: measureIndex.toDouble(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Listen to animation updates
    _scrollAnimation!.addListener(_onAnimationUpdate);

    // Start animation
    _animationController.forward(from: 0.0);
  }

  void _onAnimationUpdate() {
    if (_scrollAnimation == null) return;

    final currentValue = _scrollAnimation!.value;
    final measureIndex = currentValue.round();

    // Trigger scroll in ScoreViewer
    super._scrollToMeasure(measureIndex);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
