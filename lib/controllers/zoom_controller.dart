import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Controller for intelligent zoom management
/// Automatically adjusts zoom level based on screen size and orientation
class ZoomController extends ChangeNotifier {
  final double minZoom;
  final double maxZoom;

  double _currentZoom = 1.0;
  ZoomLevel _zoomLevel = ZoomLevel.medium;
  Size? _screenSize;
  Orientation? _orientation;

  ZoomController({
    this.minZoom = 0.5,
    this.maxZoom = 3.0,
    double initialZoom = 1.0,
  }) : _currentZoom = initialZoom.clamp(0.5, 3.0);

  /// Get current zoom value
  double get zoom => _currentZoom;

  /// Get current zoom level
  ZoomLevel get zoomLevel => _zoomLevel;

  /// Get screen size
  Size? get screenSize => _screenSize;

  /// Update screen size and recalculate optimal zoom
  void updateScreenSize(Size size, Orientation orientation) {
    final sizeChanged = _screenSize != size;
    final orientationChanged = _orientation != orientation;

    _screenSize = size;
    _orientation = orientation;

    if (sizeChanged || orientationChanged) {
      _recalculateOptimalZoom();
      notifyListeners();
    }
  }

  /// Set zoom to a specific value
  void setZoom(double zoom) {
    final newZoom = zoom.clamp(minZoom, maxZoom);
    if (_currentZoom == newZoom) return;

    _currentZoom = newZoom;
    _updateZoomLevel();
    notifyListeners();
  }

  /// Set zoom level (small, medium, large)
  void setZoomLevel(ZoomLevel level) {
    if (_zoomLevel == level) return;

    _zoomLevel = level;
    _currentZoom = _getZoomForLevel(level);
    notifyListeners();
  }

  /// Zoom in
  void zoomIn() {
    setZoom(_currentZoom + 0.1);
  }

  /// Zoom out
  void zoomOut() {
    setZoom(_currentZoom - 0.1);
  }

  /// Reset to optimal zoom for current screen
  void resetToOptimal() {
    _recalculateOptimalZoom();
    notifyListeners();
  }

  /// Calculate optimal zoom based on screen characteristics
  void _recalculateOptimalZoom() {
    if (_screenSize == null || _orientation == null) return;

    final screenWidth = _screenSize!.width;
    final screenHeight = _screenSize!.height;
    final isTablet = _isTablet(screenWidth, screenHeight);
    final isLandscape = _orientation == Orientation.landscape;

    // Calculate optimal zoom based on screen type
    double optimalZoom;

    if (isTablet) {
      // Tablets: Show 3-5 measures
      optimalZoom = isLandscape ? 0.7 : 0.9;
      _zoomLevel = ZoomLevel.small;
    } else {
      // Phones: Show 1-2 measures
      optimalZoom = isLandscape ? 1.0 : 1.3;
      _zoomLevel = ZoomLevel.medium;
    }

    _currentZoom = optimalZoom.clamp(minZoom, maxZoom);
  }

  /// Determine if device is a tablet based on screen size
  bool _isTablet(double width, double height) {
    final diagonal = _calculateDiagonal(width, height);
    // Assume tablets have diagonal >= 7 inches (at ~160 dpi)
    final minTabletDiagonal = 7 * 160 * 0.85; // ~950 dp
    return diagonal >= minTabletDiagonal;
  }

  /// Calculate screen diagonal in pixels
  double _calculateDiagonal(double width, double height) {
    return sqrt(width * width + height * height);
  }

  /// Get zoom value for a specific zoom level
  double _getZoomForLevel(ZoomLevel level) {
    if (_screenSize == null) {
      // Default values
      switch (level) {
        case ZoomLevel.small:
          return 0.8;
        case ZoomLevel.medium:
          return 1.0;
        case ZoomLevel.large:
          return 1.3;
      }
    }

    final isTablet = _isTablet(_screenSize!.width, _screenSize!.height);
    final isLandscape = _orientation == Orientation.landscape;

    if (isTablet) {
      switch (level) {
        case ZoomLevel.small:
          return isLandscape ? 0.6 : 0.8;
        case ZoomLevel.medium:
          return isLandscape ? 0.8 : 1.0;
        case ZoomLevel.large:
          return isLandscape ? 1.0 : 1.2;
      }
    } else {
      switch (level) {
        case ZoomLevel.small:
          return isLandscape ? 0.8 : 1.0;
        case ZoomLevel.medium:
          return isLandscape ? 1.0 : 1.3;
        case ZoomLevel.large:
          return isLandscape ? 1.2 : 1.5;
      }
    }
  }

  /// Update zoom level based on current zoom value
  void _updateZoomLevel() {
    if (_currentZoom < 1.0) {
      _zoomLevel = ZoomLevel.small;
    } else if (_currentZoom < 1.2) {
      _zoomLevel = ZoomLevel.medium;
    } else {
      _zoomLevel = ZoomLevel.large;
    }
  }

  /// Get recommended measures visible for current zoom
  int getVisibleMeasureCount() {
    if (_currentZoom <= 0.7) {
      return 5; // Very zoomed out
    } else if (_currentZoom <= 1.0) {
      return 3; // Normal tablet view
    } else if (_currentZoom <= 1.3) {
      return 2; // Normal phone view
    } else {
      return 1; // Zoomed in
    }
  }

  /// Format zoom as percentage
  String getZoomPercentage() {
    return '${(_currentZoom * 100).round()}%';
  }
}

/// Predefined zoom levels
enum ZoomLevel {
  small, // Show more measures (3-5)
  medium, // Balanced view (2-3 measures)
  large, // Show fewer measures for detail (1-2)
}

/// Extension to get display names
extension ZoomLevelExtension on ZoomLevel {
  String get displayName {
    switch (this) {
      case ZoomLevel.small:
        return 'Small';
      case ZoomLevel.medium:
        return 'Medium';
      case ZoomLevel.large:
        return 'Large';
    }
  }

  IconData get icon {
    switch (this) {
      case ZoomLevel.small:
        return Icons.zoom_out;
      case ZoomLevel.medium:
        return Icons.fit_screen;
      case ZoomLevel.large:
        return Icons.zoom_in;
    }
  }
}

/// Widget that automatically manages zoom based on screen size
class AdaptiveZoomBuilder extends StatelessWidget {
  final ZoomController controller;
  final Widget Function(BuildContext context, double zoom) builder;

  const AdaptiveZoomBuilder({
    super.key,
    required this.controller,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final orientation = MediaQuery.of(context).orientation;

        // Update controller with current size
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.updateScreenSize(size, orientation);
        });

        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) => builder(context, controller.zoom),
        );
      },
    );
  }
}

/// Zoom controls widget
class ZoomControls extends StatelessWidget {
  final ZoomController controller;
  final bool showPercentage;

  const ZoomControls({
    super.key,
    required this.controller,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white),
                iconSize: 20,
                onPressed: controller.zoom > controller.minZoom
                    ? controller.zoomOut
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              if (showPercentage)
                Text(
                  controller.getZoomPercentage(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                iconSize: 20,
                onPressed: controller.zoom < controller.maxZoom
                    ? controller.zoomIn
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        );
      },
    );
  }
}
