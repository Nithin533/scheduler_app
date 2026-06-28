import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../utils/date_helpers.dart';

class HabitTile extends ConsumerWidget {
  final Habit habit;

  const HabitTile({super.key, required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now().toIso8601String().split('T').first;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            habit.icon != null ? IconData(int.parse(habit.icon!), fontFamily: 'MaterialIcons') : Icons.loop,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(habit.name),
        subtitle: habit.targetValue != null
            ? Text('Target: ${habit.targetValue} ${habit.unit ?? ''} ${habit.frequency}')
            : null,
        trailing: FilledButton.tonal(
          onPressed: () {
            ref.read(habitProvider.notifier).logHabit(
                  habit.id,
                  today,
                );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${habit.name} logged for today')),
            );
          },
          child: const Text('Log'),
        ),
      ),
    );
  }
}
