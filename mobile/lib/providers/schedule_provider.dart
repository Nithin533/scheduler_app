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
    final res = await _api.get('/schedules/today');
    state = DailySchedule.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> loadSchedule(String date) async {
    final res = await _api.get('/schedules/$date');
    state = DailySchedule.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> generateSchedule(String date) async {
    final res = await _api.post('/schedules/generate',
        params: {'schedule_date': date});
    state = DailySchedule.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> confirmSchedule(int scheduleId) async {
    await _api.post('/schedules/$scheduleId/confirm');
    if (state != null && state!.id == scheduleId) {
      state = DailySchedule(
        id: state!.id,
        userId: state!.userId,
        scheduleDate: state!.scheduleDate,
        isConfirmed: true,
        totalFreeHours: state!.totalFreeHours,
        totalScheduledHours: state!.totalScheduledHours,
        isBalanced: state!.isBalanced,
        items: state!.items,
      );
    }
  }
}
