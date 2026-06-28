import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/checklist_provider.dart';
import '../../utils/date_helpers.dart';
import '../onboarding/onboarding_wizard.dart';
import '../schedule/daily_schedule_screen.dart';
import '../tasks/task_list_screen.dart';
import '../habits/habit_tracker_screen.dart';
import '../checklist/end_of_day_checklist_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/schedule_timeline.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    _DailyView(),
    TaskListScreen(),
    HabitTrackerScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(scheduleProvider.notifier).loadTodaySchedule();
      ref.read(checklistProvider.notifier).loadTodayChecklist();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.today_outlined),
              selectedIcon: Icon(Icons.today),
              label: 'Today'),
          NavigationDestination(
              icon: Icon(Icons.checklist_outlined),
              selectedIcon: Icon(Icons.checklist),
              label: 'Tasks'),
          NavigationDestination(
              icon: Icon(Icons.monitoring_outlined),
              selectedIcon: Icon(Icons.monitoring),
              label: 'Habits'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}

class _DailyView extends ConsumerWidget {
  const _DailyView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(scheduleProvider);
    final checklist = ref.watch(checklistProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateHelpers.formatDay(DateTime.now())),
            Text(
              DateHelpers.formatDate(DateTime.now()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OnboardingWizard()),
            ),
            tooltip: 'Update profile',
          ),
          if (checklist != null && !checklist.isCompleted)
            Badge(
              child: IconButton(
                icon: const Icon(Icons.event_note_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EndOfDayChecklistScreen(checklist: checklist),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(scheduleProvider.notifier).loadTodaySchedule();
          await ref.read(checklistProvider.notifier).loadTodayChecklist();
        },
        child: schedule == null
            ? const Center(child: CircularProgressIndicator())
            : ScheduleTimeline(schedule: schedule),
      ),
    );
  }
}
