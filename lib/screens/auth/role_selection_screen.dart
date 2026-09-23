import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
              // Premium Brand Emblem
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.premiumShadow,
                    border: Border.all(
                      color: AppTheme.forest.withValues(alpha: 0.12),
                      width: 2,
                    ),
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
              const SizedBox(height: 22),
              Text(
                'Smriti Saathi',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepForest,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Loving memory companion & daily wellbeing\nfor elderly family members',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.muted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 36),
              Text(
                'Select your mode to continue:',
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
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

              const SizedBox(height: 16),
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
                  label: Text(
                    'View App Features Tour',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Offline-first  •  Secure  •  Built with care for seniors',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.muted.withValues(alpha: 0.7),
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
          gradient: LinearGradient(
            colors: [
              Colors.white,
              badgeColor.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radius28),
          border: Border.all(
            color: AppTheme.divider.withValues(alpha: 0.8),
            width: 1.3,
          ),
          boxShadow: AppTheme.cardLift,
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
                    gradient: LinearGradient(
                      colors: [
                        badgeColor,
                        badgeColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radius18),
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
                          color: badgeColor.withValues(alpha: 0.6),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radius10),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.dmSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: badgeTextColor,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: GoogleFonts.dmSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
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
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
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
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
