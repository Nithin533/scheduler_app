import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/schedule.dart';
import '../services/api_client.dart';

final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, DailySchedule?>((ref) {
  return ScheduleNotifier();
});

class ScheduleNotifier extends StateNotifier<DailySchedule?> {
  final ApiClient _api = ApiClient();

  ScheduleNotifier() : super(null);

  Future<void> loadTodaySchedule() async {
    try {
      final res = await _api.get('/schedules/today');
      state = DailySchedule.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      state = null;
    }
  }

  Future<void> loadSchedule(String date) async {
    try {
      final res = await _api.get('/schedules/$date');
      state = DailySchedule.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      state = null;
    }
  }

  Future<void> generateSchedule(String date) async {
    try {
      final res = await _api.post('/schedules/generate',
          params: {'schedule_date': date});
      state = DailySchedule.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      state = null;
    }
  }

  Future<bool> confirmSchedule(int scheduleId) async {
    try {
      final res = await _api.post('/schedules/$scheduleId/confirm');
      state = DailySchedule.fromJson(res.data as Map<String, dynamic>);
      return true;
    } catch (e) {
      return false;
    }
  }
}
