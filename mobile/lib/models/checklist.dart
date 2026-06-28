class EndOfDayChecklist {
  final int id;
  final int userId;
  final DateTime checklistDate;
  final bool isCompleted;
  final DateTime? completedAt;
  final List<ChecklistItem> items;

  EndOfDayChecklist({
    required this.id,
    required this.userId,
    required this.checklistDate,
    required this.isCompleted,
    this.completedAt,
    required this.items,
  });

  factory EndOfDayChecklist.fromJson(Map<String, dynamic> json) =>
      EndOfDayChecklist(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        checklistDate: DateTime.parse(json['checklist_date'] as String),
        isCompleted: json['is_completed'] as bool? ?? false,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
        items: (json['items'] as List<dynamic>?)
                ?.map(
                    (e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class ChecklistItem {
  final int id;
  final int checklistId;
  final int? scheduleItemId;
  final String title;
  bool isChecked;
  final DateTime? checkedAt;

  ChecklistItem({
    required this.id,
    required this.checklistId,
    this.scheduleItemId,
    required this.title,
    required this.isChecked,
    this.checkedAt,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
    id: json['id'] as int,
    checklistId: json['checklist_id'] as int,
    scheduleItemId: json['schedule_item_id'] as int?,
    title: json['title'] as String,
    isChecked: json['is_checked'] as bool? ?? false,
    checkedAt: json['checked_at'] != null
        ? DateTime.parse(json['checked_at'] as String)
        : null,
  );
}
