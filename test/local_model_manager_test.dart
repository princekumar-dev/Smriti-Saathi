import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smirithi_saathi/services/local_model_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalModelManager Desktop Defaults & Variant Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('when target platform is windows/mac/linux desktop, defaultVariant is 1.5B', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        expect(LocalModelManager.isDesktop, isTrue);
        expect(LocalModelManager.defaultVariant.id, equals('qwen_1_5b'));
        expect(LocalModelManager.defaultVariant.name, contains('1.5B'));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    test('when target platform is android mobile, defaultVariant is 0.5B', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        expect(LocalModelManager.isDesktop, isFalse);
        expect(LocalModelManager.defaultVariant.id, equals('qwen_0_5b'));
        expect(LocalModelManager.defaultVariant.name, contains('0.5B'));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    test('init() defaults to 1.5B on desktop when no previous explicit choice exists', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        SharedPreferences.setMockInitialValues({});
        final manager = LocalModelManager();
        await manager.init();
        expect(manager.selectedVariant.id, equals('qwen_1_5b'));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    test('selectVariant preserves explicit user override', () async {
      SharedPreferences.setMockInitialValues({});
      final manager = LocalModelManager();
      await manager.init();

      // Switch to the other model
      final otherVariant = manager.selectedVariant.id == 'qwen_1_5b'
          ? LocalModelManager.availableModels.firstWhere((m) => m.id == 'qwen_0_5b')
          : LocalModelManager.availableModels.firstWhere((m) => m.id == 'qwen_1_5b');

      await manager.selectVariant(otherVariant);
      expect(manager.selectedVariant.id, equals(otherVariant.id));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('offline_ai_model_id'), equals(otherVariant.id));
      expect(prefs.getBool('offline_ai_explicit_choice'), isTrue);
    });
  });
}
