import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/local_ai_service.dart';
import '../services/local_model_manager.dart';
import '../services/voice_engine.dart';
import '../state/app_settings.dart';
import '../theme/app_theme.dart';
import 'animated_scale_button.dart';

class OfflineAiModal extends StatefulWidget {
  const OfflineAiModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const OfflineAiModal(),
    );
  }

  @override
  State<OfflineAiModal> createState() => _OfflineAiModalState();
}

class _OfflineAiModalState extends State<OfflineAiModal> {
  final LocalModelManager _manager = LocalModelManager();
  bool _isTesting = false;
  String? _testReply;

  @override
  void initState() {
    super.initState();
    _manager.addListener(_onManagerUpdate);
    _manager.init();
  }

  @override
  void dispose() {
    _manager.removeListener(_onManagerUpdate);
    super.dispose();
  }

  void _onManagerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _testAi(String language) async {
    setState(() {
      _isTesting = true;
      _testReply = null;
    });

    final reply = await LocalAiService.instance.generateReply(
      query: "How are you today, my friend?",
      language: language,
      userName: "Grandpa",
    );

    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _testReply = reply;
    });

    if (reply.isNotEmpty) {
      VoiceEngine().speak(reply, language: language);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final isReady = _manager.isModelReady;
    final isDownloading = _manager.status == ModelDownloadStatus.downloading;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Row
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.forest.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.offline_bolt_rounded,
                    color: AppTheme.forest,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '100% Offline AI Brain',
                        style: GoogleFonts.outfit(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.deepForest,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Qwen 2.5 On-Device • Zero Internet Needed',
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Privacy Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F7F4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.forest.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.security_rounded,
                    color: AppTheme.forest,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Complete Privacy: Dementia conversations & memories never leave this phone.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.deepForest,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Model Selection
            Text(
              'Select Model Size',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.deepForest,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: LocalModelManager.availableModels.map((variant) {
                final isSelected = _manager.selectedVariant.id == variant.id;
                final isDefault = (LocalModelManager.isDesktop && variant.id == 'qwen_1_5b') ||
                    (!LocalModelManager.isDesktop && variant.id == 'qwen_0_5b');
                return Expanded(
                  child: GestureDetector(
                    onTap: isDownloading ? null : () => _manager.selectVariant(variant),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.forest.withValues(alpha: 0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppTheme.forest : Colors.black12,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isDefault)
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.forest : const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                LocalModelManager.isDesktop ? '★ DESKTOP DEFAULT' : '★ MOBILE DEFAULT',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: isSelected ? Colors.white : AppTheme.forest,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  variant.name.split('(').first.trim(),
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? AppTheme.forest : AppTheme.deepForest,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.forest
                                      : Colors.grey.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  variant.sizeFormatted,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? Colors.white : AppTheme.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            variant.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 10.5,
                              color: AppTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Status Card
            if (isReady) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Offline AI is Ready & Active',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1B5E20),
                            ),
                          ),
                          Text(
                            '${_manager.selectedVariant.name} • 100% Local',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Test Button
              AnimatedScaleButton(
                onTap: _isTesting ? null : () => _testAi(settings.language),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.forest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: _isTesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Test Companion Offline Voice',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (_testReply != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '“$_testReply”',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.deepForest,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await _manager.deleteModel();
                    setState(() {
                      _testReply = null;
                    });
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                  label: Text(
                    'Delete Model (Reset to Not Downloaded)',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ),
            ] else if (isDownloading) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Downloading Offline AI...',
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.deepForest,
                          ),
                        ),
                        Text(
                          '${(_manager.progress * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.forest,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _manager.progress,
                        backgroundColor: Colors.black12,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.forest),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(_manager.downloadedBytes / (1024 * 1024)).toStringAsFixed(0)} MB of ${_manager.selectedVariant.sizeFormatted}',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: AppTheme.muted,
                          ),
                        ),
                        TextButton(
                          onPressed: _manager.cancelDownload,
                          child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Download Button
              AnimatedScaleButton(
                onTap: _manager.startDownload,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.forest,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.forest.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Download Offline AI (${_manager.selectedVariant.sizeFormatted})',
                        style: GoogleFonts.outfit(
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
          ],
        ),
      ),
    );
  }
}
