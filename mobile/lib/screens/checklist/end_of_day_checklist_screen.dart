import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/checklist.dart';
import '../../providers/checklist_provider.dart';

class EndOfDayChecklistScreen extends ConsumerWidget {
  final EndOfDayChecklist checklist;

  const EndOfDayChecklistScreen({super.key, required this.checklist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentChecklist = ref.watch(checklistProvider) ?? checklist;
    final unchecked =
        currentChecklist.items.where((i) => !i.isChecked).length;
    final total = currentChecklist.items.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('End of Day Review'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '${total - unchecked} of $total completed',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: total > 0 ? (total - unchecked) / total : 0,
                  ),
                  if (unchecked > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '$unchecked task${unchecked == 1 ? '' : 's'} left — '
                        'will be rescheduled if not checked',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...currentChecklist.items.map((item) {
            return Card(
              child: CheckboxListTile(
                title: Text(
                  item.title,
                  style: TextStyle(
                    decoration: item.isChecked
                        ? TextDecoration.lineThrough
                        : null,
                    color: item.isChecked ? Colors.grey : null,
                  ),
                ),
                value: item.isChecked,
                onChanged: currentChecklist.isCompleted
                    ? null
                    : (val) {
                        ref
                            .read(checklistProvider.notifier)
                            .toggleItem(
                              currentChecklist.id,
                              item.id,
                              val ?? false,
                            );
                      },
              ),
            );
          }),
          if (!currentChecklist.isCompleted && unchecked > 0)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: FilledButton.icon(
                onPressed: () async {
                  await ref
                      .read(checklistProvider.notifier)
                      .completeChecklist(currentChecklist.id);
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.done_all),
                label: const Text(
                    'Complete & Reschedule Remaining'),
              ),
            ),
          if (currentChecklist.isCompleted)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Card(
                color: Colors.green,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'All done for today!',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
