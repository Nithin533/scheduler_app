class Habit {
  final int id;
  final int userId;
  final String name;
  final String? description;
  final String? unit;
  final double? targetValue;
  final String frequency;
  final String? icon;
  final bool isActive;

  Habit({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.unit,
    this.targetValue,
    required this.frequency,
    this.icon,
    required this.isActive,
  });

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'] as int,
    userId: json['user_id'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
    unit: json['unit'] as String?,
    targetValue: json['target_value'] != null ? double.parse(json['target_value'].toString()) : null,
    frequency: json['frequency'] as String,
    icon: json['icon'] as String?,
    isActive: json['is_active'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'unit': unit,
    'target_value': targetValue,
    'frequency': frequency,
    'icon': icon,
  };
}

class HabitLog {
  final int id;
  final int habitId;
  final DateTime logDate;
  final double? value;
  final String? notes;

  HabitLog({
    required this.id,
    required this.habitId,
    required this.logDate,
    this.value,
    this.notes,
  });

  factory HabitLog.fromJson(Map<String, dynamic> json) => HabitLog(
    id: json['id'] as int,
    habitId: json['habit_id'] as int,
    logDate: DateTime.parse(json['log_date'] as String),
    value: json['value'] != null ? double.parse(json['value'].toString()) : null,
    notes: json['notes'] as String?,
  );
}
