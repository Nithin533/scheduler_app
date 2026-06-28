import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({AuthStatus? status, User? user, String? error}) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  StreamSubscription<void>? _authSub;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _authSub = ApiClient.onAuthExpired.listen((_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> tryAutoLogin() async {
    state = state.copyWith(status: AuthStatus.loading);
    final user = await _authService.tryAutoLogin();
    if (user != null) {
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      await _authService.registerDevice();
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _authService.login(email, password);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      await _authService.registerDevice();
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> register(String email, String password, {String? name}) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _authService.register(email, password, name: name);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      await _authService.registerDevice();
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
