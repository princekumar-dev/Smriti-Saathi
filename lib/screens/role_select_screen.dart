import 'package:flutter/material.dart';

import '../state/auth_session.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_mark.dart';
import 'auth_screen.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandMark(),
              const SizedBox(height: 28),
              Text(
                'Who is signing in?',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 10),
              Text(
                'Choose Caretaker or User. A caretaker registers the patient. A user logs in after that.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.muted,
                    ),
              ),
              const SizedBox(height: 28),
              _RoleCard(
                icon: Icons.volunteer_activism_rounded,
                title: 'I am a caretaker',
                subtitle: 'Sign up or log in, then register your patient.',
                color: AppTheme.sage,
                onTap: () => _openAuth(context, UserRole.caretaker),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.person_rounded,
                title: 'I am a user',
                subtitle: 'Log in with the details your caretaker created for you.',
                color: AppTheme.paleTerracotta,
                onTap: () => _openAuth(context, UserRole.user),
              ),
              const Spacer(),
              const Text(
                'Users cannot create their own account. Only a caretaker can register a patient.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
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

  void _openAuth(BuildContext context, UserRole role) {
    AuthSessionScope.of(context).selectRole(role);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AuthScreen(role: role)),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.paper,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.divider, width: 1.4),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(icon, size: 36, color: AppTheme.forest),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: AppTheme.forest),
            ],
          ),
        ),
      ),
    );
  }
}
