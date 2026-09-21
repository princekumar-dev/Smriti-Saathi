import 'package:flutter/material.dart';

import '../../navigation/app_shell.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';

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
        const SnackBar(content: Text('Please enter the code from your caretaker')),
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
            'Pass key "$code" not found in MongoDB. Try DEMO or check with your caretaker.',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final registeredPatients = auth.registeredPatients;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.forest, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Elderly Companion'),
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
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppTheme.sage,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.softShadow,
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
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.deepForest,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the code given by your family member, or tap your name below.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.muted,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              // Code Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.paper,
                  borderRadius: BorderRadius.circular(AppTheme.radius24),
                  boxShadow: AppTheme.softShadow,
                  border: Border.all(color: AppTheme.divider, width: 1.4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Enter Caretaker Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.deepForest,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _codeController,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        color: AppTheme.forest,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'e.g. SAATHI-7821',
                        hintStyle: const TextStyle(
                          fontSize: 18,
                          letterSpacing: 0,
                          fontWeight: FontWeight.normal,
                          color: AppTheme.muted,
                        ),
                        filled: true,
                        fillColor: AppTheme.cream,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radius18),
                          borderSide: const BorderSide(color: AppTheme.forest, width: 1.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => _loginWithCode(),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 58),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Start Saathi',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                    ),
                  ],
                ),
              ),

              if (registeredPatients.isNotEmpty) ...[
                const SizedBox(height: 28),
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.divider, thickness: 1.5)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR TAP YOUR PROFILE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.forest,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppTheme.divider, thickness: 1.5)),
                  ],
                ),
                const SizedBox(height: 16),
                ...registeredPatients.map((patient) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radius20),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Material(
                      color: AppTheme.paper,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radius20),
                        side: const BorderSide(color: AppTheme.divider, width: 1.2),
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
                              backgroundColor: AppTheme.sage,
                              child: const Icon(
                                Icons.person_rounded,
                                color: AppTheme.forest,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    patient.nickname.isNotEmpty
                                        ? '${patient.name} (${patient.nickname})'
                                        : patient.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.deepForest,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Age ${patient.age} • ${patient.condition}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: AppTheme.forest,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 20),

              // Instant Demo button
              TextButton.icon(
                onPressed: () => _loginWithCode('DEMO'),
                icon: const Icon(Icons.flash_on_rounded, color: AppTheme.forest),
                label: const Text(
                  'Continue as Guest / Demo Senior',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.forest,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
