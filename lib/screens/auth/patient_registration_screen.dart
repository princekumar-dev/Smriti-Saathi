import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../navigation/app_shell.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../caretaker/caretaker_dashboard_screen.dart';

class PatientRegistrationScreen extends StatefulWidget {
  final bool isInitialSetup;

  const PatientRegistrationScreen({
    super.key,
    this.isInitialSetup = false,
  });

  @override
  State<PatientRegistrationScreen> createState() =>
      _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _ageController = TextEditingController(text: '74');
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedGender;
  String _selectedCondition = 'Mild Memory Loss';
  String? _selectedLanguage;

  final List<String> _genders = ['Female', 'Male', 'Other'];
  final List<String> _conditions = [
    'Mild Memory Loss',
    'Early Alzheimer\'s',
    'Dementia Support',
    'Parkinson\'s Assistance',
    'General Senior Wellness & Companion',
  ];
  final List<String> _languages = [
    'English',
    'Hindi (हिंदी)',
    'Tamil (தமிழ்)',
    'Telugu (తెలుగు)',
    'Kannada (ಕನ್ನಡ)',
    'Bengali (বাংলা)',
    'Marathi (मराठी)',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _ageController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _fillSamplePatient() {
    setState(() {
      _nameController.text = 'Kamala Raman';
      _nicknameController.text = 'Amma';
      _ageController.text = '74';
      _selectedGender = 'Female';
      _selectedCondition = 'Mild Memory Loss';
      _selectedLanguage = 'English';
      _emergencyNameController.text = 'Meena (Daughter)';
      _emergencyPhoneController.text = '+91 98765 43210';
      _notesController.text =
          'Enjoys Carnatic music, filter coffee, morning garden walks, and childhood stories.';
    });
  }

  Future<void> _submitRegistration() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter patient/elderly name')),
      );
      return;
    }

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a gender')),
      );
      return;
    }

    if (_selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a language')),
      );
      return;
    }

    final age = int.tryParse(_ageController.text.trim()) ?? 72;
    final auth = AuthScope.of(context);

    final patient = await auth.registerPatient(
      name: name,
      nickname: _nicknameController.text.trim(),
      age: age,
      gender: _selectedGender ?? '',
      condition: _selectedCondition,
      language: _selectedLanguage ?? '',
      emergencyContact: _emergencyNameController.text.trim(),
      emergencyPhone: _emergencyPhoneController.text.trim(),
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;
    _showPairingCodeModal(patient);
  }

  void _showPairingCodeModal(PatientProfile patient) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.paper,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppTheme.sage,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.forest,
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Patient Registered Successfully!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.deepForest,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${patient.name} has been set up with personalized memory and companion routines.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.muted,
                ),
              ),
              const SizedBox(height: 24),

              // Pairing Code Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cream,
                  borderRadius: BorderRadius.circular(AppTheme.radius18),
                  border: Border.all(color: AppTheme.forest, width: 1.8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'PATIENT PAIRING CODE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.forest,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          patient.pairingCode,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.deepForest,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                    const SizedBox(height: 4),
                    const Text(
                      'Use this code when opening the app on the senior\'s phone/tablet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CaretakerDashboardScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.dashboard_rounded),
                  label: const Text('Go to Caretaker Dashboard'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final auth = AuthScope.of(context);
                    await auth.switchToPatientMode();
                    if (!mounted) return;
                    if (ctx.mounted) Navigator.pop(ctx);
                    navigator.pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const AppShell(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.elderly_rounded, color: AppTheme.forest),
                  label: const Text(
                    'Launch Elder Companion View Now',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    side: const BorderSide(color: AppTheme.forest, width: 1.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radius18),
                    ),
                  ),
                ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.forest),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Register Patient / Elder'),
        actions: [
          TextButton.icon(
            onPressed: _fillSamplePatient,
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text('Sample Data'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.paper,
                  borderRadius: BorderRadius.circular(AppTheme.radius20),
                  border: Border.all(color: AppTheme.divider, width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppTheme.forest,
                      size: 32,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Elder Companion Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.deepForest,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Saathi uses this to personalize voice conversations, memory reminders, and health alerts.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Name & Nickname
              const Text(
                'Full Name *',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.deepForest,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Kamala Raman',
                  prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.forest),
                  filled: true,
                  fillColor: AppTheme.paper,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius18),
                    borderSide: const BorderSide(color: AppTheme.divider),
                  ),
                ),
              ),

              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Calling / Pet Name',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.deepForest,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nicknameController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Amma / Dada Ji',
                            prefixIcon: const Icon(Icons.favorite_outline, color: AppTheme.forest),
                            filled: true,
                            fillColor: AppTheme.paper,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radius18),
                              borderSide: const BorderSide(color: AppTheme.divider),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 110,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Age *',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.deepForest,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '74',
                            filled: true,
                            fillColor: AppTheme.paper,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radius18),
                              borderSide: const BorderSide(color: AppTheme.divider),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Gender & Language
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gender',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.deepForest,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.paper,
                            borderRadius: BorderRadius.circular(AppTheme.radius18),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedGender,
                              isExpanded: true,
                              hint: const Text('Select Gender'),
                              items: _genders.map((g) {
                                return DropdownMenuItem(value: g, child: Text(g));
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _selectedGender = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Language',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.deepForest,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.paper,
                            borderRadius: BorderRadius.circular(AppTheme.radius18),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedLanguage,
                              isExpanded: true,
                              hint: const Text('Select Language'),
                              items: _languages.map((l) {
                                return DropdownMenuItem(value: l, child: Text(l));
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _selectedLanguage = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Memory Health Condition
              const Text(
                'Memory / Health Condition',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.deepForest,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppTheme.paper,
                  borderRadius: BorderRadius.circular(AppTheme.radius18),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCondition,
                    isExpanded: true,
                    items: _conditions.map((cond) {
                      return DropdownMenuItem(value: cond, child: Text(cond));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCondition = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Emergency Contact Info
              const Text(
                'Primary Emergency Contact',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.deepForest,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emergencyNameController,
                      decoration: InputDecoration(
                        hintText: 'Contact Name (e.g. Meena)',
                        prefixIcon: const Icon(Icons.person_outline, color: AppTheme.forest),
                        filled: true,
                        fillColor: AppTheme.paper,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radius18),
                          borderSide: const BorderSide(color: AppTheme.divider),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _emergencyPhoneController,
                      decoration: InputDecoration(
                        hintText: 'Emergency Phone',
                        prefixIcon: const Icon(Icons.phone_in_talk_rounded, color: AppTheme.forest),
                        filled: true,
                        fillColor: AppTheme.paper,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radius18),
                          borderSide: const BorderSide(color: AppTheme.divider),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Personal notes & interests
              const Text(
                'Caregiver Notes & Interests (Optional)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.deepForest,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g. Likes talking about temple visits, classical songs, grandchildren, and evening tea.',
                  filled: true,
                  fillColor: AppTheme.paper,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radius18),
                    borderSide: const BorderSide(color: AppTheme.divider),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              ElevatedButton.icon(
                onPressed: _submitRegistration,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Complete Registration & Generate Code'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
