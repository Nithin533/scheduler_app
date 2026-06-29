import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/habit_provider.dart';
import '../../widgets/habit_tile.dart';

class HabitTrackerScreen extends ConsumerStatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  ConsumerState<HabitTrackerScreen> createState() =>
      _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends ConsumerState<HabitTrackerScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(habitProvider.notifier).loadHabits();
    });
  }

  void _showAddDialog() {
    final nameCtl = TextEditingController();
    final targetCtl = TextEditingController();
    final selectedUnit = ValueNotifier<String>('g');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Habit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtl,
              decoration: const InputDecoration(labelText: 'Habit name'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: targetCtl,
                    decoration: const InputDecoration(labelText: 'Target'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<String>(
                  valueListenable: selectedUnit,
                  builder: (ctx, unit, _) => DropdownButton<String>(
                    value: unit,
                    items: 'g,tbsp,cups,ml,servings'
                        .split(',')
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) selectedUnit.value = v;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await ref.read(habitProvider.notifier).createHabit({
                'name': nameCtl.text.trim(),
                'target_value': double.tryParse(targetCtl.text),
                'unit': selectedUnit.value,
                'frequency': 'daily',
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      body: habits.isEmpty
          ? const Center(
              child: Text('No habits yet. Add one to track!'),
            )
          : ListView.builder(
              itemCount: habits.length,
              itemBuilder: (ctx, i) => HabitTile(habit: habits[i]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
