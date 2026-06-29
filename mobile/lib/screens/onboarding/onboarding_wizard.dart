import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';

class OnboardingWizard extends ConsumerStatefulWidget {
  const OnboardingWizard({super.key});

  @override
  ConsumerState<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends ConsumerState<OnboardingWizard> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  // Form data
  String? _occupation;
  String _workStart = '09:00';
  String _workEnd = '17:00';
  List<String> _workDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  bool _hasPartTime = false;
  String _partTimeStart = '18:00';
  String _partTimeEnd = '20:00';
  List<String> _partTimeDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  double _sleepTarget = 8;

  final List<Map<String, dynamic>> _sports = [];
  final List<Map<String, dynamic>> _hobbies = [];
  final List<Map<String, dynamic>> _skills = [];
  final List<Map<String, dynamic>> _longTermGoals = [];
  bool _goesToGym = false;
  int _gymDaysPerWeek = 3;
  int _gymDuration = 60;

  final List<Map<String, dynamic>> _dietItems = [];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final authService = ref.read(authServiceProvider);

    final profileData = {
      'occupation': _occupation,
      'work_start_time': _workStart,
      'work_end_time': _workEnd,
      'work_days': _workDays,
      'commute_time_minutes': 30,
      'has_part_time_job': _hasPartTime,
      'part_time_start': _hasPartTime ? _partTimeStart : null,
      'part_time_end': _hasPartTime ? _partTimeEnd : null,
      'part_time_days': _hasPartTime ? _partTimeDays : null,
      'sleep_target_hours': _sleepTarget,
      'sports': _sports,
      'hobbies': _hobbies,
      'skills_learning': _skills,
      'long_term_goals': _longTermGoals,
      'fitness_info': _goesToGym
          ? {
              'gym_days_per_week': _gymDaysPerWeek,
              'gym_duration_minutes': _gymDuration,
            }
          : null,
      'diet_tracking': _dietItems,
    };

    try {
      await authService.createProfile(profileData);
    } catch (e) {
      // Profile might already exist
    }

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Step ${_currentPage + 1} of 4'),
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: PageView(
        controller: _pageCtrl,
        onPageChanged: (i) => setState(() => _currentPage = i),
        children: [
          _BasicInfoStep(
            occupation: _occupation,
            onOccupationChanged: (v) => setState(() => _occupation = v),
            workStart: _workStart,
            onWorkStartChanged: (v) => setState(() => _workStart = v),
            workEnd: _workEnd,
            onWorkEndChanged: (v) => setState(() => _workEnd = v),
            workDays: _workDays,
            onWorkDaysChanged: (v) => setState(() => _workDays = v),
            hasPartTime: _hasPartTime,
            onHasPartTimeChanged: (v) => setState(() => _hasPartTime = v),
            partTimeStart: _partTimeStart,
            onPartTimeStartChanged: (v) => setState(() => _partTimeStart = v),
            partTimeEnd: _partTimeEnd,
            onPartTimeEndChanged: (v) => setState(() => _partTimeEnd = v),
            partTimeDays: _partTimeDays,
            onPartTimeDaysChanged: (v) => setState(() => _partTimeDays = v),
            sleepTarget: _sleepTarget,
            onSleepTargetChanged: (v) => setState(() => _sleepTarget = v),
          ),
          _InterestsStep(
            sports: _sports,
            hobbies: _hobbies,
            skills: _skills,
            goesToGym: _goesToGym,
            onGoesToGymChanged: (v) => setState(() => _goesToGym = v),
            gymDaysPerWeek: _gymDaysPerWeek,
            onGymDaysChanged: (v) => setState(() => _gymDaysPerWeek = v),
            gymDuration: _gymDuration,
            onGymDurationChanged: (v) => setState(() => _gymDuration = v),
          ),
          _GoalsStep(
            longTermGoals: _longTermGoals,
          ),
          _DietStep(
            dietItems: _dietItems,
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (_currentPage > 0)
              OutlinedButton(
                onPressed: () => _pageCtrl.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                child: const Text('Back'),
              ),
            const Spacer(),
            FilledButton(
              onPressed: _currentPage == 3
                  ? _submit
                  : () => _pageCtrl.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
              child: Text(_currentPage == 3 ? 'Done' : 'Next'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Step Widgets ---

class _BasicInfoStep extends StatefulWidget {
  final String? occupation;
  final ValueChanged<String?> onOccupationChanged;
  final String workStart, workEnd;
  final ValueChanged<String> onWorkStartChanged, onWorkEndChanged;
  final List<String> workDays;
  final ValueChanged<List<String>> onWorkDaysChanged;
  final bool hasPartTime;
  final ValueChanged<bool> onHasPartTimeChanged;
  final String partTimeStart, partTimeEnd;
  final ValueChanged<String> onPartTimeStartChanged, onPartTimeEndChanged;
  final List<String> partTimeDays;
  final ValueChanged<List<String>> onPartTimeDaysChanged;
  final double sleepTarget;
  final ValueChanged<double> onSleepTargetChanged;

  const _BasicInfoStep({
    required this.occupation,
    required this.onOccupationChanged,
    required this.workStart,
    required this.onWorkStartChanged,
    required this.workEnd,
    required this.onWorkEndChanged,
    required this.workDays,
    required this.onWorkDaysChanged,
    required this.hasPartTime,
    required this.onHasPartTimeChanged,
    required this.partTimeStart,
    required this.onPartTimeStartChanged,
    required this.partTimeEnd,
    required this.onPartTimeEndChanged,
    required this.partTimeDays,
    required this.onPartTimeDaysChanged,
    required this.sleepTarget,
    required this.onSleepTargetChanged,
  });

  @override
  State<_BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<_BasicInfoStep> {
  late TextEditingController _workStartCtl;
  late TextEditingController _workEndCtl;
  late TextEditingController _ptStartCtl;
  late TextEditingController _ptEndCtl;

  static const _dayOptions = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _workStartCtl = TextEditingController(text: widget.workStart);
    _workEndCtl = TextEditingController(text: widget.workEnd);
    _ptStartCtl = TextEditingController(text: widget.partTimeStart);
    _ptEndCtl = TextEditingController(text: widget.partTimeEnd);
  }

  @override
  void didUpdateWidget(_BasicInfoStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.workStart != oldWidget.workStart) {
      _workStartCtl.text = widget.workStart;
    }
    if (widget.workEnd != oldWidget.workEnd) {
      _workEndCtl.text = widget.workEnd;
    }
    if (widget.partTimeStart != oldWidget.partTimeStart) {
      _ptStartCtl.text = widget.partTimeStart;
    }
    if (widget.partTimeEnd != oldWidget.partTimeEnd) {
      _ptEndCtl.text = widget.partTimeEnd;
    }
  }

  @override
  void dispose() {
    _workStartCtl.dispose();
    _workEndCtl.dispose();
    _ptStartCtl.dispose();
    _ptEndCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Let's get to know you",
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Occupation (e.g., College Student)',
              prefixIcon: Icon(Icons.work_outline),
            ),
            onChanged: (v) => widget.onOccupationChanged(v),
          ),
          const SizedBox(height: 16),
          Text('Work / College Schedule',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                      labelText: 'Start', prefixText: ''),
                  controller: _workStartCtl,
                  onChanged: widget.onWorkStartChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration:
                      const InputDecoration(labelText: 'End', prefixText: ''),
                  controller: _workEndCtl,
                  onChanged: widget.onWorkEndChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _dayOptions.map((day) {
              final selected = widget.workDays.contains(day);
              return FilterChip(
                label: Text(day),
                selected: selected,
                onSelected: (sel) {
                  final updated = List<String>.from(widget.workDays);
                  sel ? updated.add(day) : updated.remove(day);
                  widget.onWorkDaysChanged(updated);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Do you have a part-time job?'),
            value: widget.hasPartTime,
            onChanged: widget.onHasPartTimeChanged,
          ),
          if (widget.hasPartTime) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'PT Start'),
                    controller: _ptStartCtl,
                    onChanged: widget.onPartTimeStartChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'PT End'),
                    controller: _ptEndCtl,
                    onChanged: widget.onPartTimeEndChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _dayOptions.map((day) {
                final selected = widget.partTimeDays.contains(day);
                return FilterChip(
                  label: Text(day),
                  selected: selected,
                  onSelected: (sel) {
                    final updated = List<String>.from(widget.partTimeDays);
                    sel ? updated.add(day) : updated.remove(day);
                    widget.onPartTimeDaysChanged(updated);
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              const Text('Sleep target: '),
              Expanded(
                child: Slider(
                  value: widget.sleepTarget,
                  min: 4,
                  max: 12,
                  divisions: 16,
                  label: '${widget.sleepTarget.toStringAsFixed(1)}h',
                  onChanged: widget.onSleepTargetChanged,
                ),
              ),
              Text('${widget.sleepTarget.toStringAsFixed(1)}h'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InterestsStep extends StatefulWidget {
  final List<Map<String, dynamic>> sports;
  final List<Map<String, dynamic>> hobbies;
  final List<Map<String, dynamic>> skills;
  final bool goesToGym;
  final ValueChanged<bool> onGoesToGymChanged;
  final int gymDaysPerWeek;
  final ValueChanged<int> onGymDaysChanged;
  final int gymDuration;
  final ValueChanged<int> onGymDurationChanged;

  const _InterestsStep({
    required this.sports,
    required this.hobbies,
    required this.skills,
    required this.goesToGym,
    required this.onGoesToGymChanged,
    required this.gymDaysPerWeek,
    required this.onGymDaysChanged,
    required this.gymDuration,
    required this.onGymDurationChanged,
  });

  @override
  State<_InterestsStep> createState() => _InterestsStepState();
}

class _InterestsStepState extends State<_InterestsStep> {
  final _sportCtl = TextEditingController();
  final _hobbyCtl = TextEditingController();
  final _skillCtl = TextEditingController();

  @override
  void dispose() {
    _sportCtl.dispose();
    _hobbyCtl.dispose();
    _skillCtl.dispose();
    super.dispose();
  }

  void _addSport() {
    if (_sportCtl.text.trim().isEmpty) return;
    widget.sports.add({'name': _sportCtl.text.trim(), 'days_per_week': 2});
    _sportCtl.clear();
    setState(() {});
  }

  void _addHobby() {
    if (_hobbyCtl.text.trim().isEmpty) return;
    widget.hobbies.add({'name': _hobbyCtl.text.trim(), 'days_per_week': 2});
    _hobbyCtl.clear();
    setState(() {});
  }

  void _addSkill() {
    if (_skillCtl.text.trim().isEmpty) return;
    widget.skills.add({'name': _skillCtl.text.trim(), 'hours_per_week': 5});
    _skillCtl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Interests & Fitness',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),

          // Sports
          Text('Sports you play:',
              style: Theme.of(context).textTheme.titleSmall),
          Row(
            children: [
              Expanded(
                  child: TextField(
                      controller: _sportCtl,
                      decoration:
                          const InputDecoration(labelText: 'Add a sport'))),
              IconButton(icon: const Icon(Icons.add), onPressed: _addSport),
            ],
          ),
          Wrap(
            spacing: 8,
            children: widget.sports
                .map((s) => Chip(
                      label: Text(s['name'] as String),
                      onDeleted: () {
                        widget.sports.remove(s);
                        setState(() {});
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

          // Hobbies
          Text('Hobbies:',
              style: Theme.of(context).textTheme.titleSmall),
          Row(
            children: [
              Expanded(
                  child: TextField(
                      controller: _hobbyCtl,
                      decoration:
                          const InputDecoration(labelText: 'Add a hobby'))),
              IconButton(icon: const Icon(Icons.add), onPressed: _addHobby),
            ],
          ),
          Wrap(
            spacing: 8,
            children: widget.hobbies
                .map((h) => Chip(
                      label: Text(h['name'] as String),
                      onDeleted: () {
                        widget.hobbies.remove(h);
                        setState(() {});
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

          // Skills
          Text('Skills you\'re learning:',
              style: Theme.of(context).textTheme.titleSmall),
          Row(
            children: [
              Expanded(
                  child: TextField(
                      controller: _skillCtl,
                      decoration: const InputDecoration(
                          labelText: 'Add a skill'))),
              IconButton(icon: const Icon(Icons.add), onPressed: _addSkill),
            ],
          ),
          Wrap(
            spacing: 8,
            children: widget.skills
                .map((s) => Chip(
                      label: Text(s['name'] as String),
                      onDeleted: () {
                        widget.skills.remove(s);
                        setState(() {});
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),

          // Gym
          SwitchListTile(
            title: const Text('Do you go to the gym?'),
            value: widget.goesToGym,
            onChanged: widget.onGoesToGymChanged,
          ),
          if (widget.goesToGym) ...[
            Row(
              children: [
                const Text('Days/week: '),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 2, label: Text('2')),
                    ButtonSegment(value: 3, label: Text('3')),
                    ButtonSegment(value: 4, label: Text('4')),
                    ButtonSegment(value: 5, label: Text('5')),
                    ButtonSegment(value: 6, label: Text('6')),
                  ],
                  selected: {widget.gymDaysPerWeek},
                  onSelectionChanged: (v) => widget.onGymDaysChanged(v.first),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Duration (min): '),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 30, label: Text('30')),
                    ButtonSegment(value: 45, label: Text('45')),
                    ButtonSegment(value: 60, label: Text('60')),
                    ButtonSegment(value: 90, label: Text('90')),
                  ],
                  selected: {widget.gymDuration},
                  onSelectionChanged: (v) =>
                      widget.onGymDurationChanged(v.first),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalsStep extends StatefulWidget {
  final List<Map<String, dynamic>> longTermGoals;

  const _GoalsStep({required this.longTermGoals});

  @override
  State<_GoalsStep> createState() => _GoalsStepState();
}

class _GoalsStepState extends State<_GoalsStep> {
  final _titleCtl = TextEditingController();
  final _pagesCtl = TextEditingController();
  final _deadlineCtl = TextEditingController();

  @override
  void dispose() {
    _titleCtl.dispose();
    _pagesCtl.dispose();
    _deadlineCtl.dispose();
    super.dispose();
  }

  void _addGoal() {
    if (_titleCtl.text.trim().isEmpty) return;
    widget.longTermGoals.add({
      'title': _titleCtl.text.trim(),
      'deadline': _deadlineCtl.text.trim().isEmpty
          ? null
          : _deadlineCtl.text.trim(),
      'pages': _pagesCtl.text.trim().isEmpty
          ? null
          : int.tryParse(_pagesCtl.text.trim()),
    });
    _titleCtl.clear();
    _pagesCtl.clear();
    _deadlineCtl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Long-Term Goals',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('e.g., "Read a book by next month", "Complete a course"',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtl,
            decoration: const InputDecoration(labelText: 'Goal title'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pagesCtl,
                  decoration:
                      const InputDecoration(labelText: 'Pages / total units'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _deadlineCtl,
                  decoration:
                      const InputDecoration(labelText: 'Deadline (YYYY-MM-DD)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: _addGoal,
              icon: const Icon(Icons.add),
              label: const Text('Add Goal'),
            ),
          ),
          const SizedBox(height: 16),
          ...widget.longTermGoals.map((g) => ListTile(
                    title: Text(g['title'] as String),
                    subtitle: Text(
                        '${g['pages'] != null ? '${g['pages']} pages - ' : ''}Deadline: ${g['deadline'] ?? 'No deadline'}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        widget.longTermGoals.remove(g);
                        setState(() {});
                      },
                    ),
                  )),
        ],
      ),
    );
  }
}

class _DietStep extends StatefulWidget {
  final List<Map<String, dynamic>> dietItems;

  const _DietStep({required this.dietItems});

  @override
  State<_DietStep> createState() => _DietStepState();
}

class _DietStepState extends State<_DietStep> {
  final _nameCtl = TextEditingController();
  final _targetCtl = TextEditingController();
  String _unit = 'g';

  @override
  void dispose() {
    _nameCtl.dispose();
    _targetCtl.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_nameCtl.text.trim().isEmpty) return;
    widget.dietItems.add({
      'item': _nameCtl.text.trim(),
      'target': '${_targetCtl.text.trim()}$_unit',
      'unit': _unit,
      'frequency': 'daily',
    });
    _nameCtl.clear();
    _targetCtl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Diet & Health Tracking',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Track things like protein intake, seed consumption, water, etc.',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _nameCtl,
                  decoration:
                      const InputDecoration(labelText: 'Item (e.g., Protein)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _targetCtl,
                  decoration: const InputDecoration(labelText: 'Target'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _unit,
                items: const [
                  DropdownMenuItem(value: 'g', child: Text('g')),
                  DropdownMenuItem(value: 'tbsp', child: Text('tbsp')),
                  DropdownMenuItem(value: 'cups', child: Text('cups')),
                  DropdownMenuItem(value: 'ml', child: Text('ml')),
                  DropdownMenuItem(value: 'servings', child: Text('servings')),
                ],
                onChanged: (v) => setState(() => _unit = v!),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
          ),
          const SizedBox(height: 16),
          ...widget.dietItems.map((d) => ListTile(
                    title: Text(d['item'] as String),
                    subtitle: Text('Target: ${d['target']} ${d['unit']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        widget.dietItems.remove(d);
                        setState(() {});
                      },
                    ),
                  )),
        ],
      ),
    );
  }
}
