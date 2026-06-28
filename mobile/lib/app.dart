import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/onboarding_wizard.dart';
import 'screens/home/home_screen.dart';
import 'screens/checklist/end_of_day_checklist_screen.dart';
import 'services/notification_service.dart';

class SchedulerApp extends ConsumerWidget {
  const SchedulerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Scheduler App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6C63FF),
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF6C63FF),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(authStateProvider.notifier).tryAutoLogin();
    });

    // Handle notification taps
    NotificationService.onNotificationTap = (data) {
      if (data == null || _navigatorKey.currentContext == null) return;

      final type = data['type'];
      if (type == 'daily_review') {
        // Navigate to home screen which shows today's schedule
        Navigator.of(_navigatorKey.currentContext!).push(
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.status.when(
      initial: () => const SplashScreen(),
      loading: () => const SplashScreen(),
      authenticated: () {
        if (authState.user == null) return const SplashScreen();
        return const HomeScreen();
      },
      unauthenticated: () => const LoginScreen(),
    );
  }
}

extension on AuthStatus {
  Widget when({
    required Widget Function() initial,
    required Widget Function() loading,
    required Widget Function() authenticated,
    required Widget Function() unauthenticated,
  }) {
    switch (this) {
      case AuthStatus.initial:
        return initial();
      case AuthStatus.loading:
        return loading();
      case AuthStatus.authenticated:
        return authenticated();
      case AuthStatus.unauthenticated:
        return unauthenticated();
    }
  }
}
