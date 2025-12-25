import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/score.dart';

/// Widget that displays a music score using OSMD (OpenSheetMusicDisplay)
/// Provides methods for highlighting measures/notes and controlling zoom
class ScoreViewer extends StatefulWidget {
  final Score score;
  final ScorePosition? currentPosition;
  final double zoom;
  final ValueChanged<String>? onError;
  final VoidCallback? onReady;

  const ScoreViewer({
    super.key,
    required this.score,
    this.currentPosition,
    this.zoom = 1.0,
    this.onError,
    this.onReady,
  });

  @override
  State<ScoreViewer> createState() => _ScoreViewerState();
}

class _ScoreViewerState extends State<ScoreViewer> {
  InAppWebViewController? _webViewController;
  bool _isReady = false;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _messageController.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(ScoreViewer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update position highlighting
    if (widget.currentPosition != oldWidget.currentPosition &&
        widget.currentPosition != null) {
      _highlightPosition(widget.currentPosition!);
    }

    // Update zoom
    if (widget.zoom != oldWidget.zoom) {
      _setZoom(widget.zoom);
    }

    // Reload score if changed
    if (widget.score.id != oldWidget.score.id) {
      _loadScore();
    }
  }

  /// Load the score into OSMD
  Future<void> _loadScore() async {
    if (_webViewController == null || !_isReady) return;

    try {
      await _webViewController!.evaluateJavascript(
        source: '''
          window.scoreViewer.loadScore(`${_escapeMusicXml(widget.score.musicXmlContent)}`);
        ''',
      );
    } catch (e) {
      widget.onError?.call('Failed to load score: $e');
    }
  }

  /// Highlight current position
  Future<void> _highlightPosition(ScorePosition position) async {
    if (_webViewController == null || !_isReady) return;

    try {
      await _webViewController!.evaluateJavascript(
        source: '''
          window.scoreViewer.highlightNote(${position.measureIndex}, ${position.noteIndex});
          window.scoreViewer.scrollToMeasure(${position.measureIndex}, true);
        ''',
      );
    } catch (e) {
      debugPrint('Failed to highlight position: $e');
    }
  }

  /// Set zoom level
  Future<void> _setZoom(double zoom) async {
    if (_webViewController == null || !_isReady) return;

    try {
      await _webViewController!.evaluateJavascript(
        source: 'window.scoreViewer.setZoom($zoom);',
      );
    } catch (e) {
      debugPrint('Failed to set zoom: $e');
    }
  }

  /// Clear all highlights
  Future<void> clearHighlights() async {
    if (_webViewController == null || !_isReady) return;

    try {
      await _webViewController!.evaluateJavascript(
        source: 'window.scoreViewer.clearHighlights();',
      );
    } catch (e) {
      debugPrint('Failed to clear highlights: $e');
    }
  }

  /// Scroll to specific measure
  Future<void> scrollToMeasure(int measureIndex, {bool smooth = true}) async {
    if (_webViewController == null || !_isReady) return;

    try {
      await _webViewController!.evaluateJavascript(
        source: 'window.scoreViewer.scrollToMeasure($measureIndex, $smooth);',
      );
    } catch (e) {
      debugPrint('Failed to scroll to measure: $e');
    }
  }

  /// Handle messages from JavaScript
  void _handleMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    final data = message['data'] as Map<String, dynamic>?;

    switch (type) {
      case 'page_ready':
        _onPageReady();
        break;
      case 'osmd_initialized':
        if (data?['success'] == true) {
          widget.onReady?.call();
        }
        break;
      case 'osmd_error':
        widget.onError?.call(data?['error'] as String? ?? 'Unknown error');
        break;
      default:
        debugPrint('Unknown message type: $type');
    }

    _messageController.add(message);
  }

  /// Called when the web page is ready
  void _onPageReady() {
    setState(() {
      _isReady = true;
    });
    _loadScore();
  }

  /// Escape MusicXML content for JavaScript string
  String _escapeMusicXml(String xml) {
    return xml
        .replaceAll('\\', '\\\\')
        .replaceAll('`', '\\`')
        .replaceAll('\$', '\\\$')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InAppWebView(
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            domStorageEnabled: true,
            databaseEnabled: true,
            allowFileAccessFromFileURLs: true,
            allowUniversalAccessFromFileURLs: true,
            mediaPlaybackRequiresUserGesture: false,
            transparentBackground: true,
          ),
          initialData: InAppWebViewInitialData(
            data: _getHtmlContent(),
            baseUrl: WebUri('https://localhost/'),
            encoding: 'utf-8',
            mimeType: 'text/html',
          ),
          onWebViewCreated: (controller) {
            _webViewController = controller;

            // Register handler for messages from JavaScript
            controller.addJavaScriptHandler(
              handlerName: 'scoreViewerMessage',
              callback: (args) {
                if (args.isNotEmpty && args[0] is Map) {
                  _handleMessage(Map<String, dynamic>.from(args[0] as Map));
                }
              },
            );
          },
          onLoadStop: (controller, url) {
            debugPrint('ScoreViewer page loaded');
          },
          onConsoleMessage: (controller, consoleMessage) {
            debugPrint('ScoreViewer console: ${consoleMessage.message}');
          },
          onLoadError: (controller, url, code, message) {
            widget.onError?.call('Failed to load web page: $message');
          },
        ),
        if (!_isReady)
          Container(
            color: Colors.white,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  /// Get HTML content from assets
  String _getHtmlContent() {
    // In production, we'll load from assets/web/score_viewer.html
    // For now, we'll inline it to avoid async loading issues
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Score Viewer</title>
    <script src="https://cdn.jsdelivr.net/npm/opensheetmusicdisplay@1.8.6/build/opensheetmusicdisplay.min.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            overflow: hidden;
            background-color: #ffffff;
        }

        #score-container {
            width: 100%;
            height: 100vh;
            overflow-y: auto;
            overflow-x: hidden;
            padding: 16px;
            scroll-behavior: smooth;
        }

        .measure-highlight {
            background-color: rgba(76, 175, 80, 0.15);
            border-radius: 4px;
            transition: all 0.2s ease;
        }

        .note-highlight {
            fill: #4CAF50 !important;
            opacity: 0.8;
        }

        .loading {
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100vh;
            font-size: 18px;
            color: #666;
        }
    </style>
</head>
<body>
    <div id="score-container">
        <div class="loading">Loading score...</div>
    </div>

    <script>
        let osmd = null;
        let currentMeasureIndex = 0;
        let currentNoteIndex = 0;
        let zoomLevel = 1.0;

        async function initializeOSMD(musicXmlContent) {
            try {
                const container = document.getElementById('score-container');
                container.innerHTML = '';

                osmd = new opensheetmusicdisplay.OpenSheetMusicDisplay(container, {
                    autoResize: true,
                    backend: 'svg',
                    drawTitle: true,
                    drawComposer: true,
                    drawPartNames: true,
                    drawMeasureNumbers: true,
                    measureNumberInterval: 1,
                    coloringEnabled: true,
                });

                await osmd.load(musicXmlContent);
                osmd.zoom = zoomLevel;
                osmd.render();

                sendMessage('osmd_initialized', { success: true });
            } catch (error) {
                console.error('Failed to initialize OSMD:', error);
                sendMessage('osmd_error', { error: error.message });
            }
        }

        function loadScore(musicXmlContent) {
            initializeOSMD(musicXmlContent);
        }

        function highlightMeasure(measureIndex) {
            if (!osmd) return;
            clearHighlights();
            currentMeasureIndex = measureIndex;
            const measures = document.querySelectorAll('g[class*="measure"]');
            if (measures[measureIndex]) {
                measures[measureIndex].classList.add('measure-highlight');
            }
            sendMessage('measure_highlighted', { measureIndex });
        }

        function highlightNote(measureIndex, noteIndex) {
            if (!osmd) return;
            highlightMeasure(measureIndex);
            currentNoteIndex = noteIndex;
            sendMessage('note_highlighted', { measureIndex, noteIndex });
        }

        function clearHighlights() {
            document.querySelectorAll('.measure-highlight').forEach(el => {
                el.classList.remove('measure-highlight');
            });
            document.querySelectorAll('.note-highlight').forEach(el => {
                el.classList.remove('note-highlight');
            });
        }

        function setZoom(zoom) {
            if (!osmd) return;
            zoomLevel = zoom;
            osmd.zoom = zoom;
            osmd.render();
            sendMessage('zoom_changed', { zoom });
        }

        function scrollToMeasure(measureIndex, smooth = true) {
            const measures = document.querySelectorAll('g[class*="measure"]');
            if (!measures[measureIndex]) return;
            const measureElement = measures[measureIndex];
            const rect = measureElement.getBoundingClientRect();
            const container = document.getElementById('score-container');
            const targetScrollTop = container.scrollTop + rect.top - window.innerHeight / 3;
            if (smooth) {
                container.scrollTo({ top: targetScrollTop, behavior: 'smooth' });
            } else {
                container.scrollTop = targetScrollTop;
            }
            sendMessage('scrolled_to_measure', { measureIndex });
        }

        function getScoreMetadata() {
            if (!osmd || !osmd.sheet) return null;
            const metadata = {
                title: osmd.sheet.Title || 'Untitled',
                composer: osmd.sheet.Composer || 'Unknown',
                measureCount: osmd.sheet.SourceMeasures.length,
                duration: osmd.sheet.SheetPlaybackManager?.Duration || 0,
            };
            sendMessage('score_metadata', metadata);
            return metadata;
        }

        function sendMessage(type, data) {
            if (window.flutter_inappwebview) {
                window.flutter_inappwebview.callHandler('scoreViewerMessage', {
                    type: type,
                    data: data,
                    timestamp: Date.now()
                });
            }
        }

        window.scoreViewer = {
            loadScore,
            highlightMeasure,
            highlightNote,
            clearHighlights,
            setZoom,
            scrollToMeasure,
            getScoreMetadata
        };

        sendMessage('page_ready', {});
    </script>
</body>
</html>
    ''';
  }
}
