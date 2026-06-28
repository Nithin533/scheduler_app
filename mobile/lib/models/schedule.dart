class DailySchedule {
  final int id;
  final int userId;
  final DateTime scheduleDate;
  final bool isConfirmed;
  final double? totalFreeHours;
  final double? totalScheduledHours;
  final bool? isBalanced;
  final List<ScheduleItem> items;

  DailySchedule({
    required this.id,
    required this.userId,
    required this.scheduleDate,
    required this.isConfirmed,
    this.totalFreeHours,
    this.totalScheduledHours,
    this.isBalanced,
    required this.items,
  });

  factory DailySchedule.fromJson(Map<String, dynamic> json) => DailySchedule(
    id: json['id'] as int,
    userId: json['user_id'] as int,
    scheduleDate: DateTime.parse(json['schedule_date'] as String),
    isConfirmed: json['is_confirmed'] as bool? ?? false,
    totalFreeHours: json['total_free_hours'] != null
        ? double.parse(json['total_free_hours'].toString())
        : null,
    totalScheduledHours: json['total_scheduled_hours'] != null
        ? double.parse(json['total_scheduled_hours'].toString())
        : null,
    isBalanced: json['is_balanced'] as bool?,
    items: (json['items'] as List<dynamic>?)
            ?.map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

class ScheduleItem {
  final int id;
  final int scheduleId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final String itemType;
  final int? taskId;
  final int? eventId;
  final int? habitId;
  final String status;
  final DateTime? completedAt;
  final int? priorityAtSchedule;

  ScheduleItem({
    required this.id,
    required this.scheduleId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.itemType,
    this.taskId,
    this.eventId,
    this.habitId,
    required this.status,
    this.completedAt,
    this.priorityAtSchedule,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) => ScheduleItem(
    id: json['id'] as int,
    scheduleId: json['schedule_id'] as int,
    title: json['title'] as String,
    startTime: DateTime.parse(json['start_time'] as String),
    endTime: DateTime.parse(json['end_time'] as String),
    durationMinutes: json['duration_minutes'] as int,
    itemType: json['item_type'] as String,
    taskId: json['task_id'] as int?,
    eventId: json['event_id'] as int?,
    habitId: json['habit_id'] as int?,
    status: json['status'] as String? ?? 'scheduled',
    completedAt: json['completed_at'] != null
        ? DateTime.parse(json['completed_at'] as String)
        : null,
    priorityAtSchedule: json['priority_at_schedule'] as int?,
  );
}
