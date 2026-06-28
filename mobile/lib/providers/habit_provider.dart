import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../services/api_client.dart';

final habitProvider = StateNotifierProvider<HabitNotifier, List<Habit>>((ref) {
  return HabitNotifier();
});

class HabitNotifier extends StateNotifier<List<Habit>> {
  final ApiClient _api = ApiClient();

  HabitNotifier() : super([]);

  Future<void> loadHabits() async {
    final res = await _api.get('/habits');
    state = (res.data as List)
        .map((e) => Habit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Habit> createHabit(Map<String, dynamic> data) async {
    final res = await _api.post('/habits', data: data);
    final habit = Habit.fromJson(res.data as Map<String, dynamic>);
    state = [...state, habit];
    return habit;
  }

  Future<void> logHabit(int habitId, String date, {double? value}) async {
    await _api.post('/habits/log', data: {
      'habit_id': habitId,
      'log_date': date,
      'value': value,
    });
  }
}
