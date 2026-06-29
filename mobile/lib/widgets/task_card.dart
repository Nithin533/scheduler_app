import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onToggleComplete,
    this.onDelete,
  });

  Color _priorityColor(int p) {
    switch (p) {
      case 1: return const Color(0xFFE74C3C);
      case 2: return const Color(0xFFF39C12);
      case 3: return const Color(0xFF3498DB);
      case 4: return const Color(0xFF2ECC71);
      case 5: return const Color(0xFF95A5A6);
      default: return Colors.grey;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'academic': return Icons.school;
      case 'work': return Icons.work;
      case 'hobby': return Icons.palette;
      case 'skill': return Icons.lightbulb;
      case 'fitness': return Icons.fitness_center;
      case 'health': return Icons.local_hospital;
      case 'chore': return Icons.cleaning_services;
      default: return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          if (onToggleComplete != null)
            SlidableAction(
              onPressed: (_) => onToggleComplete!(),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: task.isCompleted ? Icons.undo : Icons.check,
              label: task.isCompleted ? 'Undo' : 'Done',
            ),
          if (onDelete != null)
            SlidableAction(
              onPressed: (_) => onDelete!(),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _priorityColor(task.priority).withValues(alpha: 0.2),
            child: Icon(_categoryIcon(task.category),
                color: _priorityColor(task.priority), size: 20),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration:
                  task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted ? Colors.grey : null,
            ),
          ),
          subtitle: Text(
            '${task.estimatedDurationMinutes}min  •  ${task.priority == 1 ? 'Urgent' : task.priority == 2 ? 'High' : task.priority == 3 ? 'Medium' : 'Low'}'
            '${task.dueDate != null ? '  •  Due: ${task.dueDate!.toIso8601String().split('T').first}' : ''}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _priorityColor(task.priority).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'P${task.priority}',
              style: TextStyle(
                color: _priorityColor(task.priority),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
