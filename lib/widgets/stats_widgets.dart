import 'package:flutter/material.dart';
import '../models/practice_stats.dart';

/// Real-time statistics panel shown during practice
class RealtimeStatsPanel extends StatelessWidget {
  final SessionStats stats;
  final bool compact;

  const RealtimeStatsPanel({
    super.key,
    required this.stats,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactView();
    }
    return _buildFullView(context);
  }

  Widget _buildCompactView() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatItem(
            icon: Icons.check_circle,
            value: '${stats.accuracy.toInt()}%',
            color: _getAccuracyColor(stats.accuracy),
            label: 'Accuracy',
          ),
          const SizedBox(width: 16),
          _StatItem(
            icon: Icons.timer,
            value: '${stats.timingAccuracy.toInt()}%',
            color: _getAccuracyColor(stats.timingAccuracy),
            label: 'Timing',
          ),
        ],
      ),
    );
  }

  Widget _buildFullView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Practice Statistics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _GradeBadge(grade: stats.grade),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Accuracy',
                  value: '${stats.accuracy.toInt()}%',
                  subtitle: '${stats.correctNotes}/${stats.notesPlayed} correct',
                  color: _getAccuracyColor(stats.accuracy),
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Timing',
                  value: '${stats.timingAccuracy.toInt()}%',
                  subtitle: '${stats.onTimeNotes} on-time',
                  color: _getAccuracyColor(stats.timingAccuracy),
                  icon: Icons.access_time,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Progress',
                  value: '${stats.progressPercentage.toInt()}%',
                  subtitle: 'Measure ${stats.furthestMeasureReached + 1}',
                  color: Colors.blue,
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Duration',
                  value: _formatDuration(stats.duration),
                  subtitle: 'Practice time',
                  color: Colors.purple,
                  icon: Icons.schedule,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 90) return Colors.green;
    if (accuracy >= 75) return Colors.lightGreen;
    if (accuracy >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Individual stat item for compact view
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Metric card for full view
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grade badge (A, B, C, D, F)
class _GradeBadge extends StatelessWidget {
  final String grade;

  const _GradeBadge({required this.grade});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getGradeColor(),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getGradeColor().withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          grade,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getGradeColor() {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }
}

/// Session summary widget shown after practice
class SessionSummaryCard extends StatelessWidget {
  final SessionStats stats;
  final VoidCallback? onClose;
  final VoidCallback? onRetry;

  const SessionSummaryCard({
    super.key,
    required this.stats,
    this.onClose,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 64,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              'Practice Complete!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              stats.scoreTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            _GradeBadge(grade: stats.grade),
            const SizedBox(height: 8),
            Text(
              'Overall Score: ${stats.overallScore.toInt()}%',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            _SummaryRow(
              icon: Icons.check_circle,
              label: 'Accuracy',
              value: '${stats.accuracy.toInt()}%',
            ),
            _SummaryRow(
              icon: Icons.access_time,
              label: 'Timing',
              value: '${stats.timingAccuracy.toInt()}%',
            ),
            _SummaryRow(
              icon: Icons.music_note,
              label: 'Notes Played',
              value: '${stats.notesPlayed}/${stats.totalNotesInScore}',
            ),
            _SummaryRow(
              icon: Icons.schedule,
              label: 'Duration',
              value: _formatDuration(stats.duration),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (onRetry != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.replay),
                      label: const Text('Try Again'),
                    ),
                  ),
                if (onRetry != null && onClose != null)
                  const SizedBox(width: 12),
                if (onClose != null)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onClose,
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress bar showing completion
class ProgressIndicatorBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String label;

  const ProgressIndicatorBar({
    super.key,
    required this.progress,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(progress),
            ),
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.9) return Colors.green;
    if (progress >= 0.7) return Colors.lightGreen;
    if (progress >= 0.5) return Colors.orange;
    return Colors.red;
  }
}
