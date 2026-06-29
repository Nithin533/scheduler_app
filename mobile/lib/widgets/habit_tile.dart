import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';

class HabitTile extends ConsumerWidget {
  final Habit habit;

  const HabitTile({super.key, required this.habit});

  IconData _iconForHabit(String? icon) {
    if (icon == null) return Icons.loop;
    final codepoint = int.tryParse(icon);
    if (codepoint != null) {
      return IconData(codepoint, fontFamily: 'MaterialIcons');
    }
    switch (icon) {
      case 'school': return Icons.school;
      case 'work': return Icons.work;
      case 'fitness_center': return Icons.fitness_center;
      case 'book': return Icons.book;
      case 'restaurant': return Icons.restaurant;
      case 'bedtime': return Icons.bedtime;
      default: return Icons.loop;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now().toIso8601String().split('T').first;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            _iconForHabit(habit.icon),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(habit.name),
        subtitle: habit.targetValue != null
            ? Text('Target: ${habit.targetValue} ${habit.unit ?? ''} ${habit.frequency}')
            : null,
        trailing: FilledButton.tonal(
          onPressed: () async {
            await ref.read(habitProvider.notifier).logHabit(
                  habit.id,
                  today,
                );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${habit.name} logged for today')),
              );
            }
          },
          child: const Text('Log'),
        ),
      ),
    );
  }
}
