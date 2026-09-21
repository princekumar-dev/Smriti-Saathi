import 'package:flutter/material.dart';

import '../navigation/app_shell.dart';
import '../state/auth_session.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_header.dart';
import 'register_patient_screen.dart';
import 'onboarding_screen.dart';

class CaretakerHomeScreen extends StatelessWidget {
  const CaretakerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AuthSessionScope.of(context);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: session,
          builder: (context, _) {
            final patients = session.patients;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: ScreenHeader(
                    title: 'Caretaker',
                    subtitle: 'Hello, ${session.displayName}',
                    icon: Icons.volunteer_activism_rounded,
                    trailing: LabeledIconButton(
                      icon: Icons.logout_rounded,
                      label: 'Log out',
                      onTap: () => _logOut(context, session),
                      background: AppTheme.paper,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: HeroBanner(
                      title: 'Your patients',
                      subtitle:
                          'Only you can register a patient. Users log in with the details you create.',
                      icon: Icons.favorite_rounded,
                      background: AppTheme.sage,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                    child: Text(
                      patients.isEmpty ? 'No patients yet' : 'Registered patients',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                if (patients.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Tap Register patient to add the person you care for.',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.muted,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final patient = patients[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PatientCard(
                              patient: patient,
                              onOpen: () {
                                session.openPatientCompanion(patient);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const AppShell(),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        childCount: patients.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_register_patient',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const RegisterPatientScreen(),
            ),
          );
        },
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 26),
        label: const Text('Register patient'),
      ),
    );
  }

  void _logOut(BuildContext context, AuthSession session) {
    session.logOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.patient,
    required this.onOpen,
  });

  final PatientRecord patient;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.premiumCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.paleSage,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 34,
                  color: AppTheme.forest,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patient.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${patient.relationship} • Age ${patient.age}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'User login: ${patient.loginEmail}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.muted,
            ),
          ),
          if (patient.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              patient.notes,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onOpen,
              child: const Text('Open companion'),
            ),
          ),
        ],
      ),
    );
  }
}
