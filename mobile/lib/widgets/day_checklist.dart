import 'package:flutter/material.dart';
import '../models/checklist.dart';

class DayChecklist extends StatelessWidget {
  final EndOfDayChecklist checklist;
  final void Function(int itemId, bool isChecked)? onToggle;

  const DayChecklist({
    super.key,
    required this.checklist,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final unchecked = checklist.items.where((i) => !i.isChecked).length;
    final total = checklist.items.length;
    final progress = total > 0 ? (total - unchecked) / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Today\'s Tasks',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '${total - unchecked}/$total',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: unchecked == 0 ? Colors.green : null,
                    ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...checklist.items.map((item) {
          return CheckboxListTile(
            dense: true,
            title: Text(
              item.title,
              style: TextStyle(
                decoration:
                    item.isChecked ? TextDecoration.lineThrough : null,
                color: item.isChecked ? Colors.grey : null,
              ),
            ),
            value: item.isChecked,
            onChanged: checklist.isCompleted
                ? null
                : (val) => onToggle?.call(item.id, val ?? false),
          );
        }),
      ],
    );
  }
}
