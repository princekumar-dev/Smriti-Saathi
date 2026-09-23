import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/app_shell.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_scale_button.dart';

class PatientLoginScreen extends StatefulWidget {
  const PatientLoginScreen({super.key});

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loginWithCode([String? directCode]) async {
    final code = directCode ?? _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter the code from your caretaker'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius14)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = AuthScope.of(context);
    final success = await auth.loginAsPatientWithCode(code);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppShell()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pass key "$code" not found. Please check with your caretaker.',
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius14)),
        ),
      );
    }
  }

  Future<void> _selectPatient(PatientProfile patient) async {
    final auth = AuthScope.of(context);
    await auth.selectActivePatient(patient);
    await auth.switchToPatientMode();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppShell()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final registeredPatients = auth.registeredPatients
        .where((p) =>
            !p.id.toLowerCase().contains('demo') &&
            p.pairingCode != 'SAATHI-DEMO' &&
            !p.name.toLowerCase().contains('shanti devi') &&
            !p.name.toLowerCase().contains('kamala raman'))
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppTheme.forest, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Elderly Companion',
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.deepForest,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Header
              Center(
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.sage.withValues(alpha: 0.6),
                        AppTheme.paleSage,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.softShadow,
                    border: Border.all(
                      color: AppTheme.forest.withValues(alpha: 0.12),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.elderly_rounded,
                    color: AppTheme.forest,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Welcome to Saathi',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepForest,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the code given by your family member,\nor tap your name below.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.muted,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              // Code Box
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      AppTheme.paleSage.withValues(alpha: 0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radius24),
                  boxShadow: AppTheme.cardLift,
                  border: Border.all(
                    color: AppTheme.forest.withValues(alpha: 0.1),
                    width: 1.3,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Enter Caretaker Code',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.deepForest,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                        color: AppTheme.forest,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'e.g. SAATHI-7821',
                        hintStyle: GoogleFonts.dmSans(
                          fontSize: 16,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.muted.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: AppTheme.cream,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radius18),
                          borderSide: const BorderSide(
                              color: AppTheme.forest, width: 1.6),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radius18),
                          borderSide: BorderSide(
                              color:
                                  AppTheme.forest.withValues(alpha: 0.3),
                              width: 1.3),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radius18),
                          borderSide: const BorderSide(
                              color: AppTheme.forest, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedScaleButton(
                      onTap: _isLoading ? null : () => _loginWithCode(),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AppTheme.emeraldGradient,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radius18),
                          boxShadow: AppTheme.buttonGlow,
                        ),
                        child: _isLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.play_circle_filled_rounded,
                                      color: Colors.white, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Start Saathi',
                                    style: AppTheme.buttonText(
                                        fontSize: 17),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              if (registeredPatients.isNotEmpty) ...[
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Expanded(
                        child:
                            Divider(color: AppTheme.divider, thickness: 1.5)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR TAP YOUR PROFILE',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.forest,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const Expanded(
                        child:
                            Divider(color: AppTheme.divider, thickness: 1.5)),
                  ],
                ),
                const SizedBox(height: 16),
                ...registeredPatients.map((patient) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radius20),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radius20),
                        side: BorderSide(
                          color:
                              AppTheme.divider.withValues(alpha: 0.8),
                          width: 1.2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _selectPatient(patient),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor:
                                    AppTheme.paleSage.withValues(alpha: 0.6),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: AppTheme.forest,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      patient.nickname.isNotEmpty
                                          ? '${patient.name} (${patient.nickname})'
                                          : patient.name,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.deepForest,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Age ${patient.age}  •  ${patient.condition}',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: AppTheme.forest,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
