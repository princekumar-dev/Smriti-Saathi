import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/local/sync_fields.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../data/sample_data.dart';
import '../../navigation/app_shell.dart';
import '../../services/memory_service.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../auth/patient_registration_screen.dart';
import '../onboarding_screen.dart';

class CaretakerDashboardScreen extends StatefulWidget {
  const CaretakerDashboardScreen({super.key});

  @override
  State<CaretakerDashboardScreen> createState() =>
      _CaretakerDashboardScreenState();
}

class _CaretakerDashboardScreenState extends State<CaretakerDashboardScreen> {
  // Reminders live in the shared offline-first store, so what the caretaker
  // sets here is exactly what the elder sees in routine_screen (same box, same
  // patient id). Memories flow through MemoryService as before.
  final ReminderRepository _reminderRepo = ReminderRepository();
  final List<Map<String, dynamic>> _reminders = [];
  final List<Map<String, dynamic>> _memories = List.from(SampleData.memories);
  String? _patientId;
  bool _bound = false;

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bound) return;
    _bound = true;
    final auth = AuthScope.of(context);
    _patientId = auth.activePatient?.id ??
        (auth.registeredPatients.isNotEmpty
            ? auth.registeredPatients.first.id
            : null);
    _seedRemindersIfEmpty();
    _reloadReminders();
    _reminderRepo.refreshFromRemote().then((_) {
      if (mounted) _reloadReminders();
    });
  }

  void _seedRemindersIfEmpty() {
    if (_reminderRepo.getAll(patientId: _patientId).isNotEmpty) return;
    for (final r in SampleData.reminders) {
      _reminderRepo.upsert({
        kId: r['id']?.toString() ??
            'rem_${DateTime.now().microsecondsSinceEpoch}',
        if (_patientId != null) kPatientId: _patientId,
        'title': r['title'] ?? '',
        'subtitle': r['subtitle'] ?? '',
        'time': r['time'] ?? '',
        'completed': r['completed'] == true,
      });
    }
  }

  void _reloadReminders() {
    final rows = _reminderRepo.getAll(patientId: _patientId).map((r) => {
          'id': r['id'] ?? '',
          'title': r['title'] ?? '',
          'subtitle': r['subtitle'] ?? '',
          'time': r['time'] ?? '',
          'icon': Icons.medication_rounded,
          'completed': r['completed'] == true,
        });
    setState(() {
      _reminders
        ..clear()
        ..addAll(rows);
    });
  }

  /// Persist a reminder's completed flag back to the shared store.
  void _setReminderCompleted(String? id, bool completed) {
    if (id == null || id.isEmpty) return;
    final rec = _reminderRepo.getById(id);
    if (rec != null) {
      _reminderRepo.upsert({...rec, 'completed': completed});
    }
  }

  Future<void> _loadMemories() async {
    await MemoryService().loadFromDatabase();
    if (mounted) {
      setState(() {
        _memories.clear();
        _memories.addAll(MemoryService().memories.map((m) => m.toMap()));
      });
    }
  }

  void _addNewReminder() {
    final titleCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '3:00 PM');
    final subtitleCtrl = TextEditingController(text: 'Medication / Activity');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.paper,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add Patient Routine Reminder',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.deepForest,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. Afternoon Blood Pressure Tablet',
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
                  hintText: 'e.g. 3:00 PM',
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
                  hintText: 'e.g. Take with 1 glass of water',
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
                    final id = 'rem_${DateTime.now().millisecondsSinceEpoch}';
                    _reminderRepo.upsert({
                      kId: id,
                      if (_patientId != null) kPatientId: _patientId,
                      'title': titleCtrl.text.trim(),
                      'subtitle': subtitleCtrl.text.trim(),
                      'time': timeCtrl.text.trim().isNotEmpty ? timeCtrl.text.trim() : 'Now',
                      'completed': false,
                    });
                    _reloadReminders();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Routine reminder added for patient!')),
                    );
                  }
                },
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('Save Routine Reminder'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addNewMemory() {
    final titleCtrl = TextEditingController();
    final eventCtrl = TextEditingController();
    final personsCtrl = TextEditingController();
    final questionCtrl = TextEditingController();
    final answerCtrl = TextEditingController();
    final storyCtrl = TextEditingController();
    String category = 'Family';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.paper,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 28,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Add Memory with Recall Quiz',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.deepForest,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tagged persons & events will be used by Saathi for elder memory recall.',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.muted),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Trip to Mysore Palace with grandkids',
                        labelText: 'Memory Title',
                        filled: true,
                        fillColor: AppTheme.cream,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radius18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: eventCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Mysore Holiday 2023',
                        labelText: 'Event / Occasion',
                        filled: true,
                        fillColor: AppTheme.cream,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radius18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: personsCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Daughter Meena, Son Arun',
                        labelText: 'Family Members Tagged',
                        filled: true,
                        fillColor: AppTheme.cream,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radius18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: questionCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Who visited the illuminated fountains with you?',
                        labelText: 'Recall Question for Senior',
                        filled: true,
                        fillColor: AppTheme.cream,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radius18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: answerCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Son Arun',
                        labelText: 'Correct Answer',
                        filled: true,
                        fillColor: AppTheme.cream,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radius18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: storyCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Story Saathi narrates aloud to the senior...',
                        labelText: 'Memory Narrative / Story',
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
                          final persons = personsCtrl.text
                              .split(',')
                              .map((p) => p.trim())
                              .where((p) => p.isNotEmpty)
                              .toList();

                          MemoryService().addMemory(
                            title: titleCtrl.text.trim(),
                            subtitle: eventCtrl.text.trim().isNotEmpty
                                ? eventCtrl.text.trim()
                                : 'Family memory',
                            category: category,
                            event: eventCtrl.text.trim(),
                            taggedPersons: persons,
                            description: storyCtrl.text.trim().isNotEmpty
                                ? storyCtrl.text.trim()
                                : titleCtrl.text.trim(),
                            recallQuestion: questionCtrl.text.trim().isNotEmpty
                                ? questionCtrl.text.trim()
                                : 'Do you remember who was with you at ${titleCtrl.text.trim()}?',
                            recallAnswer: answerCtrl.text.trim().isNotEmpty
                                ? answerCtrl.text.trim()
                                : (persons.isNotEmpty ? persons.first : 'Family'),
                            alternativeAnswers: persons,
                            reminiscenceStory: storyCtrl.text.trim().isNotEmpty
                                ? storyCtrl.text.trim()
                                : 'A wonderful family memory.',
                          );

                          setState(() {
                            _memories.insert(0, {
                              'id': 'memory_${DateTime.now().millisecondsSinceEpoch}',
                              'title': titleCtrl.text.trim(),
                              'subtitle': storyCtrl.text.trim().isNotEmpty
                                  ? storyCtrl.text.trim()
                                  : 'A cherished family memory',
                              'category': category,
                              'description': storyCtrl.text.trim(),
                              'icon': Icons.photo_library_rounded,
                              'color': const Color(0xFFE7F0E9),
                            });
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('New memory story & AI recall question added!')),
                          );
                        }
                      },
                      icon: const Icon(Icons.favorite_rounded),
                      label: const Text('Save Memory for Patient'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final caretaker = auth.activeCaretaker;
    final patient = auth.activePatient ??
        (auth.registeredPatients.isNotEmpty
            ? auth.registeredPatients.first
            : null);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Caretaker Portal',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            Text(
              caretaker != null
                  ? '${caretaker.name} (${caretaker.relationship})'
                  : 'Family Caregiver',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.muted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.forest),
            tooltip: 'Register another patient',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PatientRegistrationScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.forest),
            tooltip: 'Switch Account / Log Out',
            onPressed: () async {
              await auth.logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Active Patient Header Card
              if (patient != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.paper,
                    borderRadius: BorderRadius.circular(AppTheme.radius24),
                    boxShadow: AppTheme.softShadow,
                    border: Border.all(color: AppTheme.divider, width: 1.4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppTheme.sage,
                            child: const Icon(
                              Icons.elderly_rounded,
                              color: AppTheme.forest,
                              size: 36,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        patient.name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.deepForest,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.sage,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Age ${patient.age}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.forest,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${patient.condition} • ${patient.language}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppTheme.divider),
                      const SizedBox(height: 12),

                      // Pairing Code Banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.cream,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.forest, width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.key_rounded,
                              color: AppTheme.forest,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Patient Pairing Code',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.forest,
                                  ),
                                ),
                                Text(
                                  patient.pairingCode,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.deepForest,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: patient.pairingCode),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Pairing code copied to clipboard!'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded, color: AppTheme.forest),
                              tooltip: 'Copy Code',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Prominent "Launch Elderly Companion View"
                      ElevatedButton.icon(
                        onPressed: () async {
                          await auth.switchToPatientMode();
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AppShell(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_circle_fill_rounded),
                        label: const Text('Launch Elderly Companion View'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 54),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // No patient registered yet
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.paper,
                    borderRadius: BorderRadius.circular(AppTheme.radius24),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.person_add_rounded, size: 48, color: AppTheme.forest),
                      const SizedBox(height: 12),
                      const Text(
                        'No Patient Registered Yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Register your elderly loved one to start managing routines and memories.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.muted),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PatientRegistrationScreen(),
                            ),
                          );
                        },
                        child: const Text('Register Patient Now'),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Wellbeing & Compliance Stats
              const Text(
                'Today\'s Senior Wellbeing',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.forest,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle_rounded,
                      iconColor: AppTheme.success,
                      title: 'Routine Status',
                      value: '${_reminders.where((r) => r['completed'] == true).length}/${_reminders.length} Done',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.record_voice_over_rounded,
                      iconColor: AppTheme.forest,
                      title: 'Voice Saathi',
                      value: '4 Talks Today',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.favorite_rounded,
                      iconColor: AppTheme.coral,
                      title: 'Mood & Safety',
                      value: 'Peaceful',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Caretaker Quick Actions
              const Text(
                'Quick Care Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.forest,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.alarm_add_rounded,
                      title: 'Add Routine / Meds',
                      onTap: _addNewReminder,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.add_photo_alternate_rounded,
                      title: 'Add Memory Story',
                      onTap: _addNewMemory,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.person_add_alt_rounded,
                      title: 'New Patient',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PatientRegistrationScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Today's Routine List for Elder
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Elderly Daily Routine',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.forest,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addNewReminder,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._reminders.map((reminder) {
                final completed = reminder['completed'] as bool;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.paper,
                    borderRadius: BorderRadius.circular(AppTheme.radius18),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            completed ? AppTheme.sage : AppTheme.cream,
                        child: Icon(
                          reminder['icon'] as IconData,
                          color: AppTheme.forest,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reminder['title'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                decoration:
                                    completed ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${reminder['time']} • ${reminder['subtitle']}',
                              style: const TextStyle(fontSize: 13, color: AppTheme.muted),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: completed,
                        activeTrackColor: AppTheme.forest,
                        activeThumbColor: Colors.white,
                        onChanged: (val) {
                          setState(() {
                            reminder['completed'] = val;
                          });
                          _setReminderCompleted(
                              reminder['id']?.toString(), val);
                        },
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),

              // Precious Memories
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Memories & Stories Bank',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.forest,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addNewMemory,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Memory'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._memories.take(3).map((memory) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.paper,
                    borderRadius: BorderRadius.circular(AppTheme.radius18),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: memory['color'] as Color? ?? AppTheme.sage,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          memory['icon'] as IconData? ?? Icons.photo_library_rounded,
                          color: AppTheme.forest,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              memory['title'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              memory['subtitle'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: AppTheme.muted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.muted),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(AppTheme.radius18),
        border: Border.all(color: AppTheme.divider, width: 1.2),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.muted,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppTheme.deepForest,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(AppTheme.radius18),
        border: Border.all(color: AppTheme.divider, width: 1.2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppTheme.sage,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.forest, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.deepForest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
