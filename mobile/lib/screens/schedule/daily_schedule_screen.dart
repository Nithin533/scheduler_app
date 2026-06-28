import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/schedule.dart';
import '../../providers/schedule_provider.dart';
import '../../utils/date_helpers.dart';
import '../../widgets/schedule_timeline.dart';

class DailyScheduleScreen extends ConsumerWidget {
  final DateTime date;

  const DailyScheduleScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(scheduleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(DateHelpers.formatDate(date)),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await ref.read(scheduleProvider.notifier).generateSchedule(
                    date.toIso8601String().split('T').first,
                  );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Regenerate'),
          ),
        ],
      ),
      body: schedule == null
          ? const Center(child: CircularProgressIndicator())
          : ScheduleTimeline(schedule: schedule),
    );
  }
}
