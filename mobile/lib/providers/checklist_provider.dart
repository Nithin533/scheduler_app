import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/checklist.dart';
import '../services/api_client.dart';

final checklistProvider =
    StateNotifierProvider<ChecklistNotifier, EndOfDayChecklist?>((ref) {
  return ChecklistNotifier();
});

class ChecklistNotifier extends StateNotifier<EndOfDayChecklist?> {
  final ApiClient _api = ApiClient();

  ChecklistNotifier() : super(null);

  Future<void> loadTodayChecklist() async {
    try {
      final res = await _api.get('/checklists/today');
      state = EndOfDayChecklist.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      state = null;
    }
  }

  Future<void> toggleItem(int checklistId, int itemId, bool isChecked) async {
    await _api.patch('/checklists/$checklistId/items/$itemId', data: {
      'is_checked': isChecked,
    });
    await loadTodayChecklist();
  }

  Future<void> completeChecklist(int checklistId) async {
    await _api.post('/checklists/$checklistId/complete');
    await loadTodayChecklist();
  }
}
