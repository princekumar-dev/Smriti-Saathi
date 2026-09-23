import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/tts/voice_model_manager.dart';
import '../services/tts/voice_model_registry.dart';

import '../state/app_settings.dart';
import '../state/auth_session.dart';
import '../state/auth_state.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../services/voice_engine.dart';
import '../widgets/fx/fade_slide_in.dart';
import '../widgets/language_selection_modal.dart';
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
                SliverToBoxAdapter(
                  child: FadeSlideIn(
                    delay: AppMotion.staggerDelay(0),
                    child: _buildProfileCard(context),
                  ),
                ),
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
                SliverToBoxAdapter(child: _sectionTitle(context, 'Voice & Speech Engine')),
                SliverToBoxAdapter(
                  child: _settingsContainer(
                    children: [
                      _buildVoicePersonaTile(context, settings),
                      _divider(),
                      _sliderTile(
                        icon: Icons.speed_rounded,
                        title: 'Voice Pace (Speed)',
                        subtitle: settings.voiceRate < 0.90
                            ? 'Very calm & patient'
                            : (settings.voiceRate <= 1.05
                                ? 'Calm & natural (Elder-tuned)'
                                : 'Slightly brisk'),
                        value: settings.voiceRate,
                        min: 0.75,
                        max: 1.25,
                        divisions: 10,
                        label: '${(settings.voiceRate * 100).toInt()}%',
                        onChanged: (val) {
                          settings.setVoiceRate(val);
                        },
                      ),
                      _divider(),
                      _sliderTile(
                        icon: Icons.graphic_eq_rounded,
                        title: 'Voice Tone & Warmth',
                        subtitle: settings.voicePitch < 0.98
                            ? 'Deeper, grounding tone'
                            : (settings.voicePitch <= 1.03
                                ? 'Natural warm tone'
                                : 'Lighter, clearer pitch'),
                        value: settings.voicePitch,
                        min: 0.90,
                        max: 1.10,
                        divisions: 8,
                        label: '${(settings.voicePitch * 100).toInt()}%',
                        onChanged: (val) {
                          settings.setVoicePitch(val);
                        },
                      ),
                      _divider(),
                      _buildTestVoiceTile(context, settings),
                      _divider(),
                      _buildOfflineVoicePackTile(context, settings),
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

  Widget _sliderTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.sage.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.forest,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.forest,
              inactiveTrackColor: AppTheme.forest.withValues(alpha: 0.18),
              thumbColor: AppTheme.forest,
              overlayColor: AppTheme.forest.withValues(alpha: 0.12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 6,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    IconData trailingIcon = Icons.chevron_right_rounded,
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
            Icon(
              trailingIcon,
              size: 28,
              color: AppTheme.forest,
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

  Widget _buildVoicePersonaTile(BuildContext context, AppSettings settings) {
    final isFemale = settings.voicePersona == 'female';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _settingIcon(Icons.face_retouching_natural_rounded),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Voice Tone & Gender',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isFemale
                          ? 'Soothing Female Voice (Warm, caring tone)'
                          : 'Soothing Male Voice (Calm, grounding tone)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    await settings.setVoicePersona('female');
                    final sample = settings.language.toLowerCase().contains('tamil')
                        ? "வணக்கம், நான் உங்கள் தோழி. நான் உங்களுடன் இருக்கிறேன்."
                        : settings.language.toLowerCase().contains('hindi')
                            ? "नमस्ते, मैं आपकी सखी हूँ। मैं आपके साथ हूँ।"
                            : "Hello, I am your soothing companion. I am right here with you.";
                    VoiceEngine().speak(sample, language: settings.language);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isFemale ? AppTheme.forest : AppTheme.cream,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isFemale ? AppTheme.forest : AppTheme.divider,
                        width: isFemale ? 2 : 1.5,
                      ),
                      boxShadow: isFemale
                          ? [
                              BoxShadow(
                                color: AppTheme.forest.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '🌸',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Soothing Female',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: isFemale ? Colors.white : AppTheme.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    await settings.setVoicePersona('male');
                    final sample = settings.language.toLowerCase().contains('tamil')
                        ? "வணக்கம், நான் உங்கள் தோழன். நான் எப்போதும் உங்கள் பக்கம் இருக்கிறேன்."
                        : settings.language.toLowerCase().contains('hindi')
                            ? "नमस्ते, मैं आपका साथी हूँ। मैं सदा आपके साथ हूँ।"
                            : "Hello, I am your gentle companion. I am right here with you.";
                    VoiceEngine().speak(sample, language: settings.language);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: !isFemale ? AppTheme.forest : AppTheme.cream,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: !isFemale ? AppTheme.forest : AppTheme.divider,
                        width: !isFemale ? 2 : 1.5,
                      ),
                      boxShadow: !isFemale
                          ? [
                              BoxShadow(
                                color: AppTheme.forest.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '🌿',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Soothing Male',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: !isFemale ? Colors.white : AppTheme.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestVoiceTile(BuildContext context, AppSettings settings) {
    return AnimatedBuilder(
      animation: VoiceEngine(),
      builder: (context, _) {
        final engine = VoiceEngine();
        final isSpeaking = engine.isSpeaking;
        final voiceName = engine.activeVoiceName;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _settingIcon(
                    isSpeaking ? Icons.volume_up_rounded : Icons.record_voice_over_rounded,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Active Voice Engine',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Model: $voiceName (${settings.language})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.forest,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (engine.canImproveVoiceQuality &&
                  engine.voiceQualityGuidance.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.warmAmber.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.warmAmber.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tips_and_updates_rounded,
                              size: 18, color: AppTheme.warmAmber),
                          const SizedBox(width: 8),
                          Text(
                            engine.isUsingPhoneticFallback
                                ? 'A clearer voice is available'
                                : 'Get an even more natural voice',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.deepForest,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        engine.voiceQualityGuidance,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              InkWell(
                onTap: () {
                  if (isSpeaking) {
                    engine.stop();
                  } else {
                    engine.testVoice(
                      language: settings.language,
                      rate: settings.voiceRate,
                      pitch: settings.voicePitch,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Playing warm sample in ${settings.language}...'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSpeaking ? AppTheme.coral : AppTheme.forest,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isSpeaking ? AppTheme.coral : AppTheme.forest)
                            .withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSpeaking ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isSpeaking ? 'Stop Voice Sample' : 'Test Saathi Voice',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfflineVoicePackTile(BuildContext context, AppSettings settings) {
    if (kIsWeb) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _settingIcon(Icons.cloud_done_rounded),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Online Natural Voice (Browser)',
                    style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'High-fidelity cloud neural voices active via Microsoft Edge / Chrome',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final model = VoiceModelRegistry.getModelFor(
      language: settings.language,
      persona: settings.voicePersona,
    );

    if (model == null || !model.isNeuralAvailable) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _settingIcon(Icons.tune_rounded),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Calibrated Device Voice',
                    style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Using calibrated native device voice for ${settings.language}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: VoiceModelManager(),
      builder: (context, _) {
        final manager = VoiceModelManager();
        final state = manager.getState(model.id);
        final progress = manager.getProgress(model.id);
        final isReady = state == VoiceModelState.ready;
        final isDownloading = state == VoiceModelState.downloading;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _settingIcon(
                    isReady
                        ? Icons.offline_bolt_rounded
                        : (isDownloading
                            ? Icons.downloading_rounded
                            : Icons.download_for_offline_outlined),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isReady
                              ? 'Offline Natural Voice Active'
                              : (isDownloading
                                  ? 'Downloading Natural Voice…'
                                  : 'Natural Offline Voice Pack'),
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isReady
                              ? '${model.speakerName} · ${model.sizeLabel} stored locally'
                              : '${model.sizeLabel} download · Speaks 100% offline afterwards',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isReady ? AppTheme.forest : AppTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isDownloading) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress > 0 ? progress : null,
                    minHeight: 6,
                    backgroundColor: AppTheme.forest.withValues(alpha: 0.12),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.forest),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(progress * 100).toInt()}% downloaded · Extracting & verifying…',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.muted,
                  ),
                ),
              ] else if (isReady) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.forest.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.forest),
                          SizedBox(width: 5),
                          Text(
                            'Ready for Offline Use',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.forest,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => manager.deleteModel(model),
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.coral),
                      label: const Text(
                        'Free space',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.coral),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => manager.downloadModel(model),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text('Download ${model.speakerName} (${model.sizeLabel})'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.forest,
                      side: BorderSide(color: AppTheme.forest.withValues(alpha: 0.35), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _chooseLanguage(BuildContext context, AppSettings settings) {
    LanguageSelectionModal.show(context);
  }
}
