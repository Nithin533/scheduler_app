import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final Task? task;

  const TaskDetailScreen({super.key, this.task});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtl;
  late final TextEditingController _descCtl;
  late final TextEditingController _durationCtl;
  int _priority = 3;
  String _category = 'other';
  String _timeSlot = 'any';
  bool _isFlexible = true;
  int? _minPerWeek;

  @override
  void initState() {
    super.initState();
    _titleCtl = TextEditingController(text: widget.task?.title ?? '');
    _descCtl = TextEditingController(text: widget.task?.description ?? '');
    _durationCtl = TextEditingController(
      text: (widget.task?.estimatedDurationMinutes ?? 30).toString(),
    );
    _priority = widget.task?.priority ?? 3;
    _category = widget.task?.category ?? 'other';
    _timeSlot = widget.task?.preferredTimeSlot ?? 'any';
    _isFlexible = widget.task?.isFlexible ?? true;
    _minPerWeek = widget.task?.minTimesPerWeek;
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _descCtl.dispose();
    _durationCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'title': _titleCtl.text.trim(),
      'description': _descCtl.text.trim(),
      'priority': _priority,
      'estimated_duration_minutes': int.tryParse(_durationCtl.text) ?? 30,
      'category': _category,
      'is_flexible': _isFlexible,
      'preferred_time_slot': _timeSlot,
      'min_times_per_week': _minPerWeek,
    };

    if (widget.task != null) {
      await ref
          .read(taskProvider.notifier)
          .updateTask(widget.task!.id, data);
    } else {
      await ref.read(taskProvider.notifier).createTask(data);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'New Task'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await ref
                    .read(taskProvider.notifier)
                    .deleteTask(widget.task!.id);
                if (mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _titleCtl,
              decoration: const InputDecoration(labelText: 'Task title'),
              validator: (v) => (v?.trim().isEmpty ?? true)
                  ? 'Title is required'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationCtl,
              decoration: const InputDecoration(
                labelText: 'Estimated duration (minutes)',
                suffixText: 'min',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Text('Priority', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [1, 2, 3, 4, 5].map((p) {
                final labels = {
                  1: 'Urgent',
                  2: 'High',
                  3: 'Medium',
                  4: 'Low',
                  5: 'Can wait'
                };
                return ChoiceChip(
                  label: Text('$p - ${labels[p]}'),
                  selected: _priority == p,
                  onSelected: (_) => setState(() => _priority = p),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('Category', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _category,
              items: const [
                DropdownMenuItem(value: 'academic', child: Text('Academic')),
                DropdownMenuItem(value: 'work', child: Text('Work')),
                DropdownMenuItem(value: 'hobby', child: Text('Hobby')),
                DropdownMenuItem(value: 'skill', child: Text('Skill')),
                DropdownMenuItem(value: 'fitness', child: Text('Fitness')),
                DropdownMenuItem(value: 'health', child: Text('Health')),
                DropdownMenuItem(value: 'chore', child: Text('Chore')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _category = v ?? 'other'),
            ),
            const SizedBox(height: 24),
            Text('Preferred Time', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'morning', label: Text('Morning')),
                ButtonSegment(value: 'afternoon', label: Text('Afternoon')),
                ButtonSegment(value: 'evening', label: Text('Evening')),
                ButtonSegment(value: 'any', label: Text('Any')),
              ],
              selected: {_timeSlot},
              onSelectionChanged: (v) =>
                  setState(() => _timeSlot = v.first),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Flexible scheduling'),
              subtitle: const Text('Allow rescheduling'),
              value: _isFlexible,
              onChanged: (v) => setState(() => _isFlexible = v),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(isEditing ? 'Update' : 'Create')),
          ],
        ),
      ),
    );
  }
}
