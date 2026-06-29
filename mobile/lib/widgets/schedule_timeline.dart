import 'package:flutter/material.dart';
import '../models/schedule.dart' as models;
import '../utils/date_helpers.dart';

class ScheduleTimeline extends StatelessWidget {
  final models.DailySchedule schedule;

  const ScheduleTimeline({super.key, required this.schedule});

  Color _typeColor(String type) {
    switch (type) {
      case 'fixed_event':
        return const Color(0xFF6C63FF);
      case 'task':
        return const Color(0xFFFF6584);
      case 'habit':
        return const Color(0xFF4ECDC4);
      case 'meal':
        return const Color(0xFFFFA500);
      case 'sleep':
        return const Color(0xFF2C3E50);
      case 'break':
        return const Color(0xFF95A5A6);
      case 'travel':
        return const Color(0xFF3498DB);
      case 'bath':
        return const Color(0xFF1ABC9C);
      case 'gym':
        return const Color(0xFFE74C3C);
      case 'free':
        return const Color(0xFFECF0F1);
      default:
        return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'fixed_event':
        return Icons.event;
      case 'task':
        return Icons.check_circle_outline;
      case 'habit':
        return Icons.loop;
      case 'meal':
        return Icons.restaurant;
      case 'sleep':
        return Icons.bedtime;
      case 'break':
        return Icons.coffee;
      case 'travel':
        return Icons.directions_car;
      case 'bath':
        return Icons.bathroom;
      case 'gym':
        return Icons.fitness_center;
      case 'free':
        return Icons.access_time;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = schedule.items;

    if (items.isEmpty) {
      return const Center(child: Text('No schedule for today'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length + 1, // +1 for summary card
      itemBuilder: (ctx, i) {
        if (i == 0) {
          return _buildSummaryCard(context);
        }
        final item = items[i - 1];
        return _buildTimelineItem(context, item);
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final completed =
        schedule.items.where((i) => i.status == 'completed').length;
    final total = schedule.items.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${schedule.totalScheduledHours?.toStringAsFixed(1) ?? '?'}h scheduled',
                      style: Theme.of(context).textTheme.titleSmall),
                  Text('${schedule.totalFreeHours?.toStringAsFixed(1) ?? '?'}h available',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (schedule.isBalanced == false)
              const Chip(
                label: Text('Overbooked'),
                backgroundColor: Colors.orange,
                labelStyle: TextStyle(color: Colors.white, fontSize: 12),
              ),
            if (schedule.isConfirmed)
              const Chip(
                label: Text('Confirmed'),
                backgroundColor: Colors.green,
                labelStyle: TextStyle(color: Colors.white, fontSize: 12),
              ),
            Text('$completed/$total',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, models.ScheduleItem item) {
    final color = _typeColor(item.itemType);
    final statusIcon = item.status == 'completed'
        ? Icons.check_circle
        : item.status == 'missed'
            ? Icons.cancel
            : item.status == 'rescheduled'
                ? Icons.replay
                : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Text(DateHelpers.formatTime(item.startTime),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                        )),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(_typeIcon(item.itemType), size: 12, color: color),
                ),
              ],
            ),
          ),
          // Timeline line
          Container(width: 2, color: color.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(horizontal: 4)),
          // Content
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                dense: true,
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: item.itemType == 'fixed_event'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (statusIcon != null)
                      Icon(statusIcon, size: 18, color: color),
                  ],
                ),
                subtitle: Text(
                  '${DateHelpers.formatTime(item.startTime)} - ${DateHelpers.formatTime(item.endTime)}  (${item.durationMinutes}min)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: item.priorityAtSchedule != null
                    ? _priorityBadge(item.priorityAtSchedule!)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priorityBadge(int priority) {
    final colors = {
      1: const Color(0xFFE74C3C),
      2: const Color(0xFFF39C12),
      3: const Color(0xFF3498DB),
      4: const Color(0xFF2ECC71),
      5: const Color(0xFF95A5A6),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors[priority]?.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'P$priority',
        style: TextStyle(
          color: colors[priority],
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
