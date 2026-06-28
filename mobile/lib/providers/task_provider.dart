import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../services/api_client.dart';

final taskProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  return TaskNotifier();
});

class TaskNotifier extends StateNotifier<List<Task>> {
  final ApiClient _api = ApiClient();

  TaskNotifier() : super([]);

  Future<void> loadTasks({String? category, bool? isCompleted}) async {
    final params = <String, dynamic>{};
    if (category != null) params['category'] = category;
    if (isCompleted != null) params['is_completed'] = isCompleted;

    final res = await _api.get('/tasks', params: params);
    final list = (res.data as List)
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList();
    state = list;
  }

  Future<Task> createTask(Map<String, dynamic> data) async {
    final res = await _api.post('/tasks', data: data);
    final task = Task.fromJson(res.data as Map<String, dynamic>);
    state = [task, ...state];
    return task;
  }

  Future<Task> updateTask(int id, Map<String, dynamic> data) async {
    final res = await _api.put('/tasks/$id', data: data);
    final task = Task.fromJson(res.data as Map<String, dynamic>);
    state = state.map((t) => t.id == id ? task : t).toList();
    return task;
  }

  Future<void> deleteTask(int id) async {
    await _api.delete('/tasks/$id');
    state = state.where((t) => t.id != id).toList();
  }

  Future<Task> completeTask(int id) async {
    final res = await _api.patch('/tasks/$id/complete');
    final task = Task.fromJson(res.data as Map<String, dynamic>);
    state = state.map((t) => t.id == id ? task : t).toList();
    return task;
  }
}
