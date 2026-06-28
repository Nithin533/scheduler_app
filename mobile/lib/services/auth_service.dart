import '../models/user.dart';
import '../services/api_client.dart';
import '../services/secure_storage.dart';
import '../services/notification_service.dart';

class AuthService {
  final ApiClient _api = ApiClient();

  Future<User> login(String email, String password) async {
    final res = await _api.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final token = res.data['access_token'] as String;
    await SecureStorage.saveToken(token);
    final meRes = await _api.get('/users/me');
    final user = User.fromJson(meRes.data as Map<String, dynamic>);
    await SecureStorage.saveUserId(user.id);
    return user;
  }

  Future<User> register(String email, String password, {String? name}) async {
    final res = await _api.post('/auth/register', data: {
      'email': email,
      'password': password,
      'name': name,
    });
    final token = res.data['access_token'] as String;
    await SecureStorage.saveToken(token);
    final meRes = await _api.get('/users/me');
    final user = User.fromJson(meRes.data as Map<String, dynamic>);
    await SecureStorage.saveUserId(user.id);
    return user;
  }

  Future<User?> tryAutoLogin() async {
    final token = await SecureStorage.getToken();
    if (token == null) return null;
    try {
      final res = await _api.get('/users/me');
      return User.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      await SecureStorage.clearAll();
      return null;
    }
  }

  Future<void> registerDevice() async {
    final token = NotificationService.fcmToken;
    if (token == null) return;
    try {
      await _api.post('/devices/register', data: {
        'fcm_token': token,
        'platform': 'android',
      });
    } catch (_) {}
  }

  Future<void> logout() async {
    await SecureStorage.clearAll();
  }

  Future<UserProfile?> getProfile() async {
    try {
      final res = await _api.get('/users/me/profile');
      return UserProfile.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<UserProfile> createProfile(Map<String, dynamic> data) async {
    final res = await _api.post('/users/me/profile', data: data);
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }
}
