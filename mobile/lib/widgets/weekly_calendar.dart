import 'package:flutter/material.dart';
import '../utils/date_helpers.dart';

class WeeklyCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Map<DateTime, int>? eventCounts;

  const WeeklyCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.eventCounts,
  });

  @override
  Widget build(BuildContext context) {
    final weekStart = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: days.map((day) {
            final isSelected = day.day == selectedDate.day &&
                day.month == selectedDate.month &&
                day.year == selectedDate.year;
            final isToday = DateHelpers.isToday(day);
            final count = eventCounts?.entries
                .where((e) =>
                    e.key.day == day.day &&
                    e.key.month == day.month &&
                    e.key.year == day.year)
                .fold(0, (sum, e) => sum + e.value);

            return GestureDetector(
              onTap: () => onDateSelected(day),
              child: Container(
                width: 40,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : isToday
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      DateHelpers.formatShortDay(day)[0],
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontWeight: isSelected || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : null,
                      ),
                    ),
                    if (count != null && count > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
