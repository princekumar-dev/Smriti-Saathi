import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smirithi_saathi/main.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('App loads onboarding and shows language selection modal when not selected', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SmirithiSaathiApp());
    // Pump through splash screen transition
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Language selection modal appears
    expect(find.textContaining('Language'), findsWidgets);
  });

  testWidgets('App loads onboarding screen directly when language is already selected', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'smirithi_has_selected_language': true,
      'smirithi_language': 'English',
    });
    await tester.pumpWidget(const SmirithiSaathiApp());
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('Saathi'), findsWidgets);
  });
}
