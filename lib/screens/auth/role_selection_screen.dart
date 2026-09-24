import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/app_assets.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_scale_button.dart';
import '../../widgets/fx/fade_slide_in.dart';
import 'caretaker_auth_screen.dart';
import 'patient_login_screen.dart';

/// ===============================================================
/// ROLE SELECTION — "Who is using the app?"
/// A calm, welcoming fork the user meets before the auth screens:
/// pick Patient (elder — enter the caretaker code) or Caregiver
/// (family — sign up / log in), reconfirm language, then continue.
/// ===============================================================
enum _Role { patient, caregiver }

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  _Role? _selectedRole;

  void _continue() {
    final role = _selectedRole;
    if (role == null) return;
    final Widget destination = role == _Role.caregiver
        ? const CaretakerAuthScreen()
        : const PatientLoginScreen();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBrandHeader(),
                    const SizedBox(height: 30),
                    FadeSlideIn(
                      delay: AppMotion.staggerDelay(2),
                      child: _buildRolePrompt(),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      delay: AppMotion.staggerDelay(3),
                      child: _RoleCard(
                        icon: Icons.self_improvement_rounded,
                        accent: AppTheme.forest,
                        soft: AppTheme.paleSage,
                        title: 'Patient',
                        subtitle: 'I am using the app for myself',
                        selected: _selectedRole == _Role.patient,
                        onTap: () =>
                            setState(() => _selectedRole = _Role.patient),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FadeSlideIn(
                      delay: AppMotion.staggerDelay(4),
                      child: _RoleCard(
                        icon: Icons.volunteer_activism_rounded,
                        accent: AppTheme.coral,
                        soft: AppTheme.paleCoral,
                        title: 'Caregiver',
                        subtitle: 'I am helping a loved one',
                        selected: _selectedRole == _Role.caregiver,
                        onTap: () =>
                            setState(() => _selectedRole = _Role.caregiver),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Brand lockup: emblem, wordmark, tagline ──
  Widget _buildBrandHeader() {
    return Column(
      children: [
        FadeSlideIn(
          delay: AppMotion.staggerDelay(0),
          child: Container(
            width: 92,
            height: 92,
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
            child: AppAssets.logo(fit: BoxFit.contain, fallbackSize: 44),
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: AppMotion.staggerDelay(1),
          child: Column(
            children: [
              Text(
                'Smriti Saathi',
                textAlign: TextAlign.center,
                style: GoogleFonts.comfortaa(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepForest,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'A friend for every memory',
                textAlign: TextAlign.center,
                style: GoogleFonts.caveat(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.forest.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRolePrompt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Who is using the app?',
          style: GoogleFonts.dmSans(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: AppTheme.deepForest,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Choose your role to get started',
          style: GoogleFonts.dmSans(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: AppTheme.muted,
          ),
        ),
      ],
    );
  }

  // ── Persistent Get Started bar ──
  Widget _buildBottomBar() {
    final enabled = _selectedRole != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        color: AppTheme.cream,
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepForest.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: AnimatedScaleButton(
        onTap: enabled ? _continue : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: enabled ? 1.0 : 0.5,
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              gradient: AppTheme.emeraldGradient,
              borderRadius: BorderRadius.circular(AppTheme.radius18),
              boxShadow: enabled ? AppTheme.buttonGlow : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Get Started',
                  style: AppTheme.buttonText(fontSize: 17),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 21),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Selectable role card: soft-tinted avatar, title + subtitle, and a
/// trailing chevron that turns into a check when the card is chosen.
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final Color soft;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.accent,
    required this.soft,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScaleButton(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: selected
                ? [Colors.white, soft.withValues(alpha: 0.7)]
                : [Colors.white, Colors.white],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radius28),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.75)
                : AppTheme.divider.withValues(alpha: 0.8),
            width: selected ? 2 : 1.3,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.2),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: soft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: 0.28),
                  width: 1.4,
                ),
              ),
              child: Icon(icon, size: 30, color: accent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.deepForest,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.muted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? accent : Colors.transparent,
                border: Border.all(
                  color: selected ? accent : AppTheme.divider,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18)
                  : Icon(Icons.chevron_right_rounded,
                      color: accent.withValues(alpha: 0.7), size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
