import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/task_provider.dart';
import '../../widgets/task_card.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  String? _categoryFilter;
  bool? _completedFilter;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(taskProvider.notifier).loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskProvider);

    var filtered = tasks.toList();
    if (_categoryFilter != null) {
      filtered = filtered.where((t) => t.category == _categoryFilter).toList();
    }
    if (_completedFilter != null) {
      filtered =
          filtered.where((t) => t.isCompleted == _completedFilter).toList();
    }
    filtered.sort((a, b) => a.priority.compareTo(b.priority));

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                DropdownButton<String?>(
                  value: _categoryFilter,
                  hint: const Text('All Categories'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ...['academic', 'work', 'hobby', 'skill', 'fitness',
                        'health', 'chore', 'other']
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (v) => setState(() => _categoryFilter = v),
                ),
                const Spacer(),
                SegmentedButton<bool?>(
                  segments: const [
                    ButtonSegment(value: null, label: Text('All')),
                    ButtonSegment(value: false, label: Text('Active')),
                    ButtonSegment(value: true, label: Text('Done')),
                  ],
                  selected: {_completedFilter},
                  onSelectionChanged: (v) =>
                      setState(() => _completedFilter = v.first),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No tasks yet. Add one!'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => TaskCard(
                      task: filtered[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TaskDetailScreen(task: filtered[i]),
                        ),
                      ).then((_) =>
                          ref.read(taskProvider.notifier).loadTasks()),
                      onToggleComplete: () async {
                        await ref
                            .read(taskProvider.notifier)
                            .completeTask(filtered[i].id);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TaskDetailScreen()),
        ).then((_) => ref.read(taskProvider.notifier).loadTasks()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
