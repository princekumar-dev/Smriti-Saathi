import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../services/api_service.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_scale_button.dart';
import '../widgets/fx/fade_slide_in.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  final List<Map<String, dynamic>> _reminders = List.from(SampleData.reminders);

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final rems = await ApiService().fetchReminders();
    if (rems.isNotEmpty && mounted) {
      setState(() {
        _reminders.clear();
        _reminders.addAll(rems.map((r) => {
          'id': r['id'] ?? '',
          'title': r['title'] ?? '',
          'subtitle': r['subtitle'] ?? '',
          'time': r['time'] ?? '',
          'icon': Icons.alarm_on_rounded,
          'completed': r['completed'] == true,
        }));
      });
    }
  }

  void _toggleReminder(int index) {
    setState(() {
      final current = _reminders[index]['completed'] as bool;
      _reminders[index]['completed'] = !current;
    });

    final nowCompleted = _reminders[index]['completed'] as bool;
    final remId = _reminders[index]['id']?.toString();
    if (remId != null && remId.isNotEmpty) {
      ApiService().updateReminder(remId, {'completed': nowCompleted});
    }

    if (nowCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Wonderful! "${_reminders[index]['title']}" completed.'),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _addReminderDialog() {
    final titleCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '4:00 PM');
    final subtitleCtrl = TextEditingController(text: 'Medication / Activity');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.paper,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add Routine Reminder',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.deepForest,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. Evening Herbal Tea',
                  labelText: 'Reminder Title',
                  filled: true,
                  fillColor: AppTheme.cream,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. 5:30 PM',
                  labelText: 'Scheduled Time',
                  filled: true,
                  fillColor: AppTheme.cream,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subtitleCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. Drink warm with biscuits',
                  labelText: 'Care Notes',
                  filled: true,
                  fillColor: AppTheme.cream,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius18),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  if (titleCtrl.text.isNotEmpty) {
                    final newRem = {
                      'id': 'rem_${DateTime.now().millisecondsSinceEpoch}',
                      'title': titleCtrl.text.trim(),
                      'subtitle': subtitleCtrl.text.trim(),
                      'time': timeCtrl.text.trim().isNotEmpty ? timeCtrl.text.trim() : 'Now',
                      'icon': Icons.alarm_on_rounded,
                      'completed': false,
                    };
                    setState(() {
                      _reminders.add(newRem);
                    });
                    ApiService().saveReminder(newRem);
                    Navigator.pop(ctx);
                  }
                },
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('Add to Today\'s Schedule'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _reminders.where((r) => r['completed'] == true).length;
    final total = _reminders.length;
    final percent = total > 0 ? (completedCount / total) : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Daily Routine',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.alarm_add_rounded, color: AppTheme.forest, size: 28),
            onPressed: _addReminderDialog,
            tooltip: 'Add Routine Item',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Overview Card
              FadeSlideIn(
                delay: AppMotion.staggerDelay(0),
                child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppTheme.emeraldGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radius28),
                  boxShadow: AppTheme.elevatedShadow,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: percent,
                            strokeWidth: 7,
                            backgroundColor: Colors.white.withValues(alpha: 0.25),
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                          ),
                          Text(
                            '${(percent * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$completedCount of $total completed',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            completedCount == total
                                ? 'All tasks complete for today! Wonderful.'
                                : 'Take your time. Each small step matters.',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ),

              const SizedBox(height: 24),

              FadeSlideIn(
                delay: AppMotion.staggerDelay(1),
                child: const Text(
                'Today\'s Schedule',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.deepForest,
                ),
              ),
              ),
              const SizedBox(height: 12),

              // Routine Timeline Cards or Empty State
              if (_reminders.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.paper,
                    borderRadius: BorderRadius.circular(AppTheme.radius24),
                    border: Border.all(color: AppTheme.divider, width: 1.2),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.sage.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.alarm_on_rounded,
                          size: 40,
                          color: AppTheme.forest,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'No Reminders for Today',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.deepForest,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Keep track of daily medications, meals, hydration, and restful evening routines.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.muted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _addReminderDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.forest,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radius16),
                          ),
                        ),
                        icon: const Icon(Icons.add_alarm_rounded, size: 18),
                        label: const Text('Add Reminder', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                )
              else
                ...List.generate(_reminders.length, (index) {
                  final reminder = _reminders[index];
                  final completed = reminder['completed'] as bool;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AnimatedScaleButton(
                    onTap: () => _toggleReminder(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: completed ? AppTheme.paleSage : AppTheme.paper,
                        borderRadius: BorderRadius.circular(AppTheme.radius24),
                        border: Border.all(
                          color: completed ? AppTheme.forest : AppTheme.divider,
                          width: completed ? 1.6 : 1.2,
                        ),
                        boxShadow: completed ? [] : AppTheme.softShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: completed ? AppTheme.forest : AppTheme.sage,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              reminder['icon'] as IconData? ?? Icons.alarm_on_rounded,
                              color: completed ? Colors.white : AppTheme.forest,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: completed ? AppTheme.forest.withValues(alpha: 0.15) : AppTheme.paleTerracotta,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        reminder['time'] as String,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: completed ? AppTheme.forest : AppTheme.terracotta,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  reminder['title'] as String,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.deepForest,
                                    decoration: completed ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  reminder['subtitle'] as String,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: completed ? AppTheme.forest : AppTheme.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: completed ? AppTheme.success : Colors.transparent,
                              border: Border.all(
                                color: completed ? AppTheme.success : AppTheme.divider,
                                width: 2.0,
                              ),
                            ),
                            child: completed
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
