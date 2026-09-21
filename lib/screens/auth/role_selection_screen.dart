import 'package:flutter/material.dart';

import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_scale_button.dart';
import '../onboarding_screen.dart';
import 'caretaker_auth_screen.dart';
import 'patient_login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Brand Icon Emblem
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.elevatedShadow,
                    border: Border.all(color: AppTheme.forest.withValues(alpha: 0.15), width: 2),
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.favorite_rounded,
                      color: AppTheme.forest,
                      size: 48,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Smriti Saathi',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.deepForest,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Loving memory companion & daily wellbeing for elderly family members',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.muted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 36),
              const Text(
                'Select your mode to continue:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.forest,
                ),
              ),
              const SizedBox(height: 16),

              // Option 1: Caretaker / Family
              _RoleCard(
                icon: Icons.health_and_safety_rounded,
                badge: 'FAMILY & CAREGIVERS',
                badgeColor: AppTheme.sage,
                badgeTextColor: AppTheme.forest,
                title: 'I am a Caretaker / Family',
                subtitle:
                    'Sign up or log in to register your patient, set medication reminders, add family memories & track wellbeing.',
                buttonText: 'Open Caretaker Portal',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CaretakerAuthScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              // Option 2: Elderly Companion
              _RoleCard(
                icon: Icons.person_pin_rounded,
                badge: 'SENIOR COMPANION',
                badgeColor: AppTheme.paleCoral,
                badgeTextColor: AppTheme.coral,
                title: 'I am the Elderly User',
                subtitle:
                    'Connect with your caretaker code, chat with Voice Saathi, look at memories, and see your daily routine.',
                buttonText: 'Open Elderly Companion',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PatientLoginScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // Instant Demo Action
              AnimatedScaleButton(
                onTap: () async {
                  final auth = AuthScope.of(context);
                  await auth.loginAsPatientWithCode('DEMO');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: AppTheme.paper,
                    borderRadius: BorderRadius.circular(AppTheme.radius20),
                    border: Border.all(color: AppTheme.forest, width: 2.0),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flash_on_rounded, color: AppTheme.forest, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Explore Instant Demo Mode',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.deepForest,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OnboardingScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline_rounded, size: 20),
                  label: const Text('View App Features Tour'),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Offline-first • Secure • Built with care for seniors',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String badge;
  final Color badgeColor;
  final Color badgeTextColor;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.badge,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppTheme.paper,
          borderRadius: BorderRadius.circular(AppTheme.radius28),
          border: Border.all(color: AppTheme.divider, width: 1.4),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, size: 32, color: badgeTextColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: badgeTextColor,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.deepForest,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  buttonText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: badgeTextColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: badgeTextColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
