class FixedEvent {
  final int id;
  final int userId;
  final String title;
  final String? description;
  final int? dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isRecurring;
  final String category;
  final String? color;

  FixedEvent({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isRecurring,
    required this.category,
    this.color,
  });

  factory FixedEvent.fromJson(Map<String, dynamic> json) => FixedEvent(
    id: json['id'] as int,
    userId: json['user_id'] as int,
    title: json['title'] as String,
    description: json['description'] as String?,
    dayOfWeek: json['day_of_week'] as int?,
    startTime: json['start_time'] as String,
    endTime: json['end_time'] as String,
    isRecurring: json['is_recurring'] as bool? ?? false,
    category: json['category'] as String,
    color: json['color'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'day_of_week': dayOfWeek,
    'start_time': startTime,
    'end_time': endTime,
    'is_recurring': isRecurring,
    'category': category,
    'color': color,
  };
}
