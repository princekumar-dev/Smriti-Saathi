import 'package:flutter/material.dart';

import '../state/app_settings.dart';
import '../state/auth_session.dart';
import '../state/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_header.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) {
            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: ScreenHeader(
                    title: 'Settings',
                    subtitle: 'Make the app easier to use',
                    showBack: true,
                  ),
                ),
                SliverToBoxAdapter(child: _buildProfileCard(context)),
                SliverToBoxAdapter(child: _sectionTitle(context, 'Easier reading')),
                SliverToBoxAdapter(
                  child: _settingsContainer(
                    children: [
                      _switchTile(
                        icon: Icons.text_fields_rounded,
                        title: 'Large text',
                        subtitle: 'Make words bigger and clearer',
                        value: settings.largeText,
                        onChanged: settings.setLargeText,
                      ),
                      _divider(),
                      _switchTile(
                        icon: Icons.volume_up_rounded,
                        title: 'Voice responses',
                        subtitle: 'Saathi speaks answers aloud',
                        value: settings.voiceResponses,
                        onChanged: settings.setVoiceResponses,
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(child: _sectionTitle(context, 'Language')),
                SliverToBoxAdapter(
                  child: _settingsContainer(
                    children: [
                      _actionTile(
                        icon: Icons.language_rounded,
                        title: 'Language',
                        subtitle: settings.language,
                        onTap: () => _chooseLanguage(context, settings),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(child: _sectionTitle(context, 'App preferences')),
                SliverToBoxAdapter(
                  child: _settingsContainer(
                    children: [
                      _switchTile(
                        icon: Icons.wifi_off_rounded,
                        title: 'Offline-first mode',
                        subtitle: 'Keep essential features available offline',
                        value: settings.offlineMode,
                        onChanged: settings.setOfflineMode,
                      ),
                      _divider(),
                      _switchTile(
                        icon: Icons.notifications_active_rounded,
                        title: 'Reminders',
                        subtitle: 'Receive routine reminders',
                        value: settings.notifications,
                        onChanged: settings.setNotifications,
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(child: _sectionTitle(context, 'About')),
                SliverToBoxAdapter(
                  child: _settingsContainer(
                    children: [
                      _actionTile(
                        icon: Icons.info_outline_rounded,
                        title: 'About Smriti Saathi',
                        onTap: () {},
                      ),
                      _divider(),
                      _actionTile(
                        icon: Icons.security_rounded,
                        title: 'Privacy & data',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 36)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    String name = 'Amma';
    String roleLabel = 'Senior Companion';

    try {
      final auth = AuthScope.of(context);
      if (auth.activePatient != null) {
        name = auth.activePatient!.nickname.isNotEmpty
            ? '${auth.activePatient!.name} (${auth.activePatient!.nickname})'
            : auth.activePatient!.name;
        roleLabel = 'Pass Key: ${auth.activePatient!.pairingCode}';
      }
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.softGreenCard,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: AppTheme.paper,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 36,
                    color: AppTheme.forest,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        roleLabel,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.coral,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final nav = Navigator.of(context);
                  final auth = AuthScope.of(context);
                  AuthSession? session;
                  try {
                    session = AuthSessionScope.of(context);
                  } catch (_) {}

                  await auth.logout();
                  session?.logOut();

                  nav.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log Out / Switch Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _settingsContainer({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radius24),
          boxShadow: AppTheme.softShadow,
        ),
        child: Material(
          color: AppTheme.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius24),
            side: const BorderSide(color: AppTheme.divider, width: 1.4),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _settingIcon(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            activeTrackColor: AppTheme.forest,
            activeThumbColor: Colors.white,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _settingIcon(icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 30,
              color: AppTheme.muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingIcon(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.sage,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppTheme.forest, size: 26),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, indent: 76, endIndent: 16);
  }

  void _chooseLanguage(BuildContext context, AppSettings settings) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose language',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _languageOption(context, settings, 'English'),
              _languageOption(context, settings, 'தமிழ்'),
              _languageOption(context, settings, 'తెలుగు'),
              _languageOption(context, settings, 'हिन्दी'),
            ],
          ),
        );
      },
    );
  }

  Widget _languageOption(
    BuildContext context,
    AppSettings settings,
    String language,
  ) {
    final selected = settings.language == language;
    return InkWell(
      onTap: () {
        settings.setLanguage(language);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                language,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.forest,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
