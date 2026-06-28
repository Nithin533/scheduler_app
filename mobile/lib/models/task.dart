class Task {
  final int id;
  final int userId;
  final String title;
  final String? description;
  final int priority;
  final int estimatedDurationMinutes;
  final String category;
  final DateTime? dueDate;
  final bool isCompleted;
  final bool isFlexible;
  final String preferredTimeSlot;
  final int? minTimesPerWeek;
  final double progress;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.priority,
    required this.estimatedDurationMinutes,
    required this.category,
    this.dueDate,
    required this.isCompleted,
    required this.isFlexible,
    required this.preferredTimeSlot,
    this.minTimesPerWeek,
    required this.progress,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as int,
    userId: json['user_id'] as int,
    title: json['title'] as String,
    description: json['description'] as String?,
    priority: json['priority'] as int,
    estimatedDurationMinutes: json['estimated_duration_minutes'] as int,
    category: json['category'] as String,
    dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
    isCompleted: json['is_completed'] as bool? ?? false,
    isFlexible: json['is_flexible'] as bool? ?? true,
    preferredTimeSlot: json['preferred_time_slot'] as String? ?? 'any',
    minTimesPerWeek: json['min_times_per_week'] as int?,
    progress: double.parse(json['progress'].toString()),
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'priority': priority,
    'estimated_duration_minutes': estimatedDurationMinutes,
    'category': category,
    'due_date': dueDate?.toIso8601String().split('T').first,
    'is_flexible': isFlexible,
    'preferred_time_slot': preferredTimeSlot,
    'min_times_per_week': minTimesPerWeek,
  };
}
