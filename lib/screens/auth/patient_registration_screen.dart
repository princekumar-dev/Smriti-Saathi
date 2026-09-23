import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/app_translations.dart';
import '../../navigation/app_shell.dart';
import '../../state/app_settings.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_scale_button.dart';
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
  late final List<String> _languages = AppTranslations.supportedLanguages
      .map((l) => l.englishName == 'English' ? 'English' : '${l.englishName} (${l.nativeName})')
      .toList();

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
                decoration: BoxDecoration(
                  gradient: AppTheme.emeraldGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.buttonGlow,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Patient Registered!',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepForest,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${patient.name} has been set up with personalized\nmemory and companion routines.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Pairing Code Box
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.cream,
                      AppTheme.paleSage.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radius18),
                  border: Border.all(
                    color: AppTheme.forest,
                    width: 1.8,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'PATIENT PAIRING CODE',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
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
                          style: GoogleFonts.dmSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
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
                                content: Text(
                                    'Pairing code copied to clipboard!'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded,
                              color: AppTheme.forest),
                          tooltip: 'Copy Code',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Use this code when opening the app\non the senior\'s phone/tablet.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
                  label: Text(
                    'Go to Caretaker Dashboard',
                    style: AppTheme.buttonText(),
                  ),
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
                  icon: const Icon(Icons.elderly_rounded,
                      color: AppTheme.forest),
                  label: Text(
                    'Launch Elder Companion View Now',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.forest,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    side: const BorderSide(
                        color: AppTheme.forest, width: 1.6),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radius18),
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

  InputDecoration _premiumInput({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTheme.inputHint(),
      prefixIcon: Icon(icon, color: AppTheme.forest),
      filled: true,
      fillColor: AppTheme.paper,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius18),
        borderSide: BorderSide(
            color: AppTheme.divider.withValues(alpha: 0.8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius18),
        borderSide: BorderSide(
            color: AppTheme.divider.withValues(alpha: 0.8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius18),
        borderSide: const BorderSide(
            color: AppTheme.forest, width: 1.8),
      ),
    );
  }

  Widget _premiumLabel(String text, {bool required = false}) {
    return Text.rich(
      TextSpan(
        text: text,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppTheme.deepForest,
        ),
        children: required
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppTheme.coral),
                ),
              ]
            : null,
      ),
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
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppTheme.forest),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Register Patient / Elder',
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.deepForest,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      AppTheme.paleSage.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radius20),
                  border: Border.all(
                    color: AppTheme.forest.withValues(alpha: 0.1),
                    width: 1.2,
                  ),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.paleSage,
                            AppTheme.sage.withValues(alpha: 0.5),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radius14),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: AppTheme.forest,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Elder Companion Profile',
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.deepForest,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Saathi uses this to personalize voice conversations, memory reminders, and health alerts.',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Name & Nickname
              _premiumLabel('Full Name', required: true),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: AppTheme.inputText(),
                decoration: _premiumInput(
                  hintText: 'e.g. Kamala Raman',
                  icon: Icons.badge_outlined,
                ),
              ),

              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _premiumLabel('Calling / Pet Name'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nicknameController,
                          style: AppTheme.inputText(),
                          decoration: _premiumInput(
                            hintText: 'e.g. Amma / Dada Ji',
                            icon: Icons.favorite_outline,
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
                        _premiumLabel('Age', required: true),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          style: AppTheme.inputText(),
                          decoration: _premiumInput(
                            hintText: '74',
                            icon: Icons.cake_outlined,
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
                        _premiumLabel('Gender'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.paper,
                            borderRadius: BorderRadius.circular(
                                AppTheme.radius18),
                            border: Border.all(
                                color: AppTheme.divider),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedGender,
                              isExpanded: true,
                              hint: Text(
                                'Select Gender',
                                style: AppTheme.inputHint(),
                              ),
                              style: AppTheme.inputText(),
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppTheme.forest,
                              ),
                              items: _genders.map((g) {
                                return DropdownMenuItem(
                                    value: g, child: Text(g));
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _selectedGender = val);
                                if (val != null) {
                                  AppSettingsScope.of(context).autoSyncWithGender(val);
                                }
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
                        _premiumLabel('Language'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.paper,
                            borderRadius: BorderRadius.circular(
                                AppTheme.radius18),
                            border: Border.all(
                                color: AppTheme.divider),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedLanguage,
                              isExpanded: true,
                              hint: Text(
                                'Select Language',
                                style: AppTheme.inputHint(),
                              ),
                              style: AppTheme.inputText(),
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppTheme.forest,
                              ),
                              items: _languages.map((l) {
                                return DropdownMenuItem(
                                    value: l, child: Text(l));
                              }).toList(),
                              onChanged: (val) {
                                setState(() =>
                                    _selectedLanguage = val);
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
              _premiumLabel('Memory / Health Condition'),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppTheme.paper,
                  borderRadius:
                      BorderRadius.circular(AppTheme.radius18),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCondition,
                    isExpanded: true,
                    style: AppTheme.inputText(),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.forest,
                    ),
                    items: _conditions.map((cond) {
                      return DropdownMenuItem(
                          value: cond, child: Text(cond));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() =>
                            _selectedCondition = val);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Emergency Contact Info
              _premiumLabel('Primary Emergency Contact'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emergencyNameController,
                      style: AppTheme.inputText(),
                      decoration: _premiumInput(
                        hintText: 'Contact Name',
                        icon: Icons.person_outline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _emergencyPhoneController,
                      style: AppTheme.inputText(),
                      decoration: _premiumInput(
                        hintText: 'Emergency Phone',
                        icon: Icons.phone_in_talk_rounded,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Personal notes & interests
              _premiumLabel('Caregiver Notes & Interests'),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                style: AppTheme.inputText(),
                decoration: InputDecoration(
                  hintText:
                      'e.g. Likes talking about temple visits, classical songs, grandchildren, and evening tea.',
                  hintStyle: AppTheme.inputHint(),
                  filled: true,
                  fillColor: AppTheme.paper,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        AppTheme.radius18),
                    borderSide: BorderSide(
                        color: AppTheme.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        AppTheme.radius18),
                    borderSide: BorderSide(
                        color: AppTheme.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        AppTheme.radius18),
                    borderSide: const BorderSide(
                        color: AppTheme.forest, width: 1.8),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              AnimatedScaleButton(
                onTap: _submitRegistration,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppTheme.emeraldGradient,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radius18),
                    boxShadow: AppTheme.buttonGlow,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.save_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Complete Registration & Generate Code',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.buttonText(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
