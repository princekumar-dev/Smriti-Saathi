import 'package:flutter/material.dart';

import '../data/repositories/family_repository.dart';
import '../data/local/sync_fields.dart';
import '../data/sample_data.dart';
import '../state/auth_state.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_scale_button.dart';
import '../widgets/fx/fade_slide_in.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  // Offline-first store (Hive-backed, best-effort server sync). Screens read
  // and write only through the repository — never ApiService directly.
  final FamilyRepository _repo = FamilyRepository();
  final List<Map<String, dynamic>> _familyMembers = [];
  String? _patientId;
  bool _bound = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bound) return;
    _bound = true;
    _patientId = AuthScope.of(context).activePatient?.id;
    _seedIfEmpty();
    _reload();
    // Pull anything newer from the server, then re-render.
    _repo.refreshFromRemote().then((_) {
      if (mounted) _reload();
    });
  }

  /// First run has no saved family — seed the local store from the sample set
  /// once so the circle isn't empty, then everything persists offline.
  void _seedIfEmpty() {
    if (_repo.getAll(patientId: _patientId).isNotEmpty) return;
    for (final m in SampleData.familyMembers) {
      _repo.upsert({
        kId: m['id']?.toString() ??
            'fam_${DateTime.now().microsecondsSinceEpoch}',
        if (_patientId != null) kPatientId: _patientId,
        'name': m['name'] ?? '',
        'relation': m['relation'] ?? 'Family',
        'phone': m['phone'] ?? '',
      });
    }
  }

  /// Re-read the repository and map records to display rows (icon/color are
  /// presentation-only and never persisted).
  void _reload() {
    final rows = _repo.getAll(patientId: _patientId).map((m) => {
          'id': m['id'] ?? '',
          'name': m['name'] ?? '',
          'relation': m['relation'] ?? 'Family',
          'phone': m['phone'] ?? '',
          'icon': Icons.person_rounded,
          'color': AppTheme.sage,
        });
    setState(() {
      _familyMembers
        ..clear()
        ..addAll(rows);
    });
  }

  void _callMember(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius28),
          ),
          title: Row(
            children: [
              const Icon(Icons.phone_in_talk_rounded, color: AppTheme.forest, size: 28),
              const SizedBox(width: 12),
              Text('Call ${member['name']}?'),
            ],
          ),
          content: Text(
            'Connecting you to ${member['name']} (${member['relation']}) at ${member['phone']}.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Dialing ${member['name']}...')),
                );
              },
              child: const Text('Start Call'),
            ),
          ],
        );
      },
    );
  }

  void _addFamilyMemberDialog() {
    final nameCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

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
                'Add Family Member',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.deepForest,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. Meena',
                  labelText: 'Name',
                  filled: true,
                  fillColor: AppTheme.cream,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relationCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. Daughter, Grandson, Brother',
                  labelText: 'Relationship',
                  filled: true,
                  fillColor: AppTheme.cream,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '+91 98765 00000',
                  labelText: 'Phone Number',
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
                  if (nameCtrl.text.isNotEmpty) {
                    final id = 'fam_${DateTime.now().millisecondsSinceEpoch}';
                    _repo.upsert({
                      kId: id,
                      if (_patientId != null) kPatientId: _patientId,
                      'name': nameCtrl.text.trim(),
                      'relation': relationCtrl.text.trim().isNotEmpty
                          ? relationCtrl.text.trim()
                          : 'Family',
                      'phone': phoneCtrl.text.trim().isNotEmpty
                          ? phoneCtrl.text.trim()
                          : '+91 90000 00000',
                    });
                    _reload();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Family member added and saved!')),
                    );
                  }
                },
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Save to Family Circle'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Family Circle',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.forest, size: 28),
            onPressed: _addFamilyMemberDialog,
            tooltip: 'Add Family Member',
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
              // Emergency SOS Card
              FadeSlideIn(
                delay: AppMotion.staggerDelay(0),
                child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.coralGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radius28),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.coral.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sos_rounded,
                        color: AppTheme.coral,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency SOS',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Tap to immediately alert your primary caregiver & family.',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedScaleButton(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppTheme.coral,
                            content: Text('🚨 Emergency alert sent to caregiver!'),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.radius16),
                        ),
                        child: const Text(
                          'ALERT',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.coral,
                          ),
                        ),
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
                'Your Loved Ones',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.deepForest,
                ),
              ),
              ),
              const SizedBox(height: 12),

              // Family List or Empty State
              if (_familyMembers.isEmpty)
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
                          Icons.group_add_rounded,
                          size: 40,
                          color: AppTheme.forest,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'No Family Members Added',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.deepForest,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Add children, grandchildren, or relatives so Saathi can help recognize them and offer quick calling.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.muted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _addFamilyMemberDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.forest,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radius16),
                          ),
                        ),
                        icon: const Icon(Icons.person_add_rounded, size: 18),
                        label: const Text('Add Family Member', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                )
              else
                ..._familyMembers.map((member) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AnimatedScaleButton(
                    onTap: () => _callMember(member),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.paper,
                        borderRadius: BorderRadius.circular(AppTheme.radius24),
                        border: Border.all(color: AppTheme.divider, width: 1.3),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: member['color'] as Color? ?? AppTheme.sage,
                            child: const Icon(
                              Icons.person_rounded,
                              size: 34,
                              color: AppTheme.forest,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member['name'] as String,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.deepForest,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  member['relation'] as String,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.forest,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  member['phone'] as String,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.sage,
                              shape: BoxShape.circle,
                              boxShadow: AppTheme.softShadow,
                            ),
                            child: const Icon(
                              Icons.call_rounded,
                              color: AppTheme.forest,
                              size: 24,
                            ),
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
